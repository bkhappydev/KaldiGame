import 'dart:convert';

class LevelTable {
  int? level;
  double? score;


  LevelTable({
    this.level,
    this.score,
  });

  factory LevelTable.fromRawJson(String str) =>
      LevelTable.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory LevelTable.fromJson(Map<String, dynamic> json) =>
      LevelTable(
        level: json["level"],
        score: json["score"],

      );

  Map<String, dynamic> toJson() => {
    "level": level,
    "score": score,
  };
}
