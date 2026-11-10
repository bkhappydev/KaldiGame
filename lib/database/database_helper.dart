import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/database/tables/item_table.dart';
import 'package:kaldi_app/database/tables/level_table.dart';
import 'package:kaldi_app/utils/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as io;

class DataBaseHelper {
  static final DataBaseHelper instance = DataBaseHelper.internal();

  factory DataBaseHelper() => instance;

  Database? _db;

  DataBaseHelper.internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await init();
    return _db!;
  }

  /// Version of the bundled database (its `PRAGMA user_version`). Version 2
  /// added the English item names; version 3 added quizzes 51-60 (letters,
  /// grains, jobs, toys, heritage, culture).
  static const int bundledDbVersion = 3;

  /// Fingerprint of the bundled database the installed copy was made from.
  /// Any change to the asset changes it, so an app update always brings the
  /// new questions and picture paths, even if [bundledDbVersion] was not
  /// bumped.
  static const String _fingerprintKey = "BUNDLED_DB_FINGERPRINT";

  init() async {
    var dbPath = await getDatabasesPath();

    String dbPathKidsGames = path.join(dbPath, "KidsGamesFlutter.db");

    final Uint8List bundled = await _bundledDb();
    final String fingerprint = _fingerprint(bundled);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await io.File(dbPathKidsGames).exists()) {
      await io.File(dbPathKidsGames).writeAsBytes(bundled, flush: true);
      await prefs.setString(_fingerprintKey, fingerprint);
      return _db = await openDatabase(dbPathKidsGames);
    }

    Database database = await openDatabase(dbPathKidsGames);
    final int installedVersion = await database.getVersion();
    if (installedVersion < bundledDbVersion ||
        prefs.getString(_fingerprintKey) != fingerprint) {
      // Replace the outdated copy but keep the player's progress.
      final List<Map<String, dynamic>> scores = await database.rawQuery(
        "SELECT level, score FROM $levelTable",
      );
      await database.close();
      await deleteDatabase(dbPathKidsGames);
      await io.File(dbPathKidsGames).writeAsBytes(bundled, flush: true);
      await prefs.setString(_fingerprintKey, fingerprint);
      database = await openDatabase(dbPathKidsGames);
      final Batch batch = database.batch();
      for (final row in scores) {
        batch.update(
          levelTable,
          {'score': row['score']},
          where: 'level = ?',
          whereArgs: [row['level']],
        );
      }
      await batch.commit(noResult: true);
      Debug.printLog(
        "Database upgraded $installedVersion -> $bundledDbVersion, "
        "restored ${scores.length} scores",
      );
    }

    return _db = database;
  }

  Future<Uint8List> _bundledDb() async {
    // Asset keys always use "/", whatever the platform.
    final ByteData data = await rootBundle.load(
      "assets/database/KidsGamesFlutter.db",
    );
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Length plus a 32-bit FNV-1a hash: cheap, and enough to spot any edit.
  static String _fingerprint(Uint8List bytes) {
    int hash = 0x811c9dc5;
    for (final int b in bytes) {
      hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return "${bytes.length}-${hash.toRadixString(16)}";
  }

  String itemTable = "ItemTable";
  String levelTable = "LevelTable";

  Future<List<ItemTable>> getItemData(int categoryId) async {
    List<ItemTable> itemList = [];
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.rawQuery(
      "SELECT * FROM $itemTable where level = $categoryId",
    );

    if (maps.isNotEmpty) {
      for (var answer in maps) {
        var itemData = ItemTable.fromJson(answer);
        itemList.add(itemData);
      }
    }

    return itemList;
  }

  Future<List<LevelTable>> getLevelData() async {
    List<LevelTable> levelList = [];
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.rawQuery(
      "SELECT * FROM $levelTable",
    );
    if (maps.isNotEmpty) {
      for (var answer in maps) {
        var levelData = LevelTable.fromJson(answer);
        levelList.add(levelData);
      }
    }
    return levelList;
  }

  /// Bumped after every score save. The category and quiz lists listen to it
  /// to refresh their stars, however the player navigates back to them.
  static final ValueNotifier<int> scoresChanged = ValueNotifier<int>(0);

  Future<int> updateScore(int? level, double score) async {
    Map<String, dynamic> row = {'score': score};
    var dbClient = await db;
    var result = await dbClient.update(
      levelTable,
      row,
      where: 'level = ?',
      whereArgs: [level],
    );
    Debug.printLog("updated score: $result");
    scoresChanged.value++;
    return result;
  }
}
