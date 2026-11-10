import 'dart:convert';

class ItemTable {
  int? level;
  int? itemId;
  String? itemName;
  String? itemNameEn;
  String? itemImage;

  ItemTable({
    this.level,
    this.itemId,
    this.itemName,
    this.itemNameEn,
    this.itemImage,
  });

  /// The answer text in the given language code ("am" or "en"). Falls back to
  /// the Amharic name if no translation exists.
  String nameFor(String languageCode) {
    if (languageCode == 'en' && (itemNameEn?.isNotEmpty ?? false)) {
      return itemNameEn!;
    }
    return itemName ?? '';
  }

  factory ItemTable.fromRawJson(String str) =>
      ItemTable.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ItemTable.fromJson(Map<String, dynamic> json) => ItemTable(
        level: json["level"],
        itemId: json["item_id"],
        itemName: json["item_name"],
        itemNameEn: json["item_name_en"],
        itemImage: json["item_image"],
      );

  Map<String, dynamic> toJson() => {
        "level": level,
        "item_id": itemId,
        "item_name": itemName,
        "item_name_en": itemNameEn,
        "item_image": itemImage,
      };
}
