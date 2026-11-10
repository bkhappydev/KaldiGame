import 'package:flutter/material.dart';

/// A sweet a child can win from a gift box.
class Treat {
  /// Also the name of its 3D picture in assets/3d (e.g. chocolate.png).
  final String id;
  final String nameEn;
  final String nameAm;

  /// Glow colour of the plate behind the treat.
  final Color color;

  const Treat(this.id, this.nameEn, this.nameAm, this.color);

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : nameAm;
}

class Treats {
  Treats._();

  static const List<Treat> all = [
    Treat('chocolate', 'Chocolate', 'ቸኮሌት', Color(0XFF8B4A2B)),
    Treat('candy', 'Candy', 'ከረሜላ', Color(0XFFFF6FA8)),
    Treat('lollipop', 'Lollipop', 'ሎሊፖፕ', Color(0XFFB86BFF)),
    Treat('cupcake', 'Cupcake', 'ካፕኬክ', Color(0XFFFF8FAB)),
    Treat('popcorn', 'Popcorn', 'ፈንዲሻ', Color(0XFFFFC93C)),
    Treat('donut', 'Donut', 'ዶናት', Color(0XFFFF9F6B)),
    Treat('icecream', 'Ice cream', 'አይስክሬም', Color(0XFF7FD8FF)),
    Treat('cookie', 'Cookie', 'ብስኩት', Color(0XFFD9A566)),
    Treat('honey', 'Honey', 'ማር', Color(0XFFF5B700)),
    Treat('cake', 'Cake', 'ኬክ', Color(0XFFFFB3C7)),
    Treat('cherries', "Kaldi's cherries", 'የቡና ፍሬ', Color(0XFFD7263D)),
    Treat('pudding', 'Pudding', 'ፑዲንግ', Color(0XFFE8B36A)),
  ];

  /// The order gifts are handed out in. Every treat is won once before any
  /// repeats, starting with the classics (chocolate, candy, lollipop).
  static const List<int> giftOrder = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  /// The treat inside the gift with this index (0 = first gift ever).
  static Treat forGift(int giftIndex) =>
      all[giftOrder[giftIndex % giftOrder.length]];

  /// Bright wrapping-paper colours for the 3D gift boxes.
  static const List<List<Color>> wrapColors = [
    [Color(0XFFFF5A5F), Color(0XFFFFC93C)],
    [Color(0XFF00B4D8), Color(0XFFFFFFFF)],
    [Color(0XFF9B5DE5), Color(0XFFFFC93C)],
    [Color(0XFF3CB878), Color(0XFFFF5A5F)],
    [Color(0XFFFF8FAB), Color(0XFF9B5DE5)],
  ];
}
