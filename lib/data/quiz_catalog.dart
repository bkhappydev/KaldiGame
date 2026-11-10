import 'package:flutter/material.dart';

/// One quiz (a "level" in the database) with a short topic name.
class QuizInfo {
  /// Level number in the database (1-60). Scores are stored against it.
  final int level;
  final String nameEn;
  final String nameAm;

  const QuizInfo(this.level, this.nameEn, this.nameAm);

  String nameFor(String languageCode) => languageCode == 'am' ? nameAm : nameEn;
}

/// A group of related quizzes shown on the home screen.
class QuizCategory {
  final String id;
  final String nameEn;
  final String nameAm;

  /// Item picture used as the category's cover (path under assets/, no
  /// extension, same format as ItemTable.itemImage).
  final String coverImage;
  final IconData icon;

  /// Card gradient, top to bottom.
  final List<Color> colors;

  /// Quizzes in play order (roughly easiest first), not database order.
  final List<QuizInfo> quizzes;

  const QuizCategory({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    required this.coverImage,
    required this.icon,
    required this.colors,
    required this.quizzes,
  });

  String nameFor(String languageCode) => languageCode == 'am' ? nameAm : nameEn;

  /// The category's 3D picture in assets/3d (an Icon3D name).
  String get icon3d => 'cat_$id';

  int get count => quizzes.length;
}

/// The 60 quizzes grouped into 10 categories of 6. Every level appears in
/// exactly one category (checked by [QuizCatalog.debugValidate]).
class QuizCatalog {
  QuizCatalog._();

  static const List<QuizCategory> categories = [
    QuizCategory(
      id: 'basics',
      nameEn: 'Numbers, Colours & Shapes',
      nameAm: 'ቁጥሮች፣ ቀለሞችና ቅርጾች',
      coverImage: 'items/8/5',
      icon: Icons.interests_rounded,
      colors: [Color(0XFFFFB86B), Color(0XFFE8740C)],
      quizzes: [
        QuizInfo(15, 'Numbers', 'ቁጥሮች'),
        QuizInfo(6, 'Colours', 'ቀለሞች'),
        QuizInfo(8, 'Shapes', 'ቅርጾች'),
        QuizInfo(51, 'Amharic Letters', 'ፊደላት'),
        QuizInfo(52, 'English Letters', 'የእንግሊዝኛ ፊደላት'),
        QuizInfo(13, 'Maths Signs', 'የሂሳብ ምልክቶች'),
      ],
    ),
    QuizCategory(
      id: 'animals',
      nameEn: 'Animals & Nature',
      nameAm: 'እንስሳትና ተፈጥሮ',
      coverImage: 'items/39/3',
      icon: Icons.pets_rounded,
      colors: [Color(0XFF8EE07A), Color(0XFF2E9E3E)],
      quizzes: [
        QuizInfo(10, 'Farm Animals', 'የቤት እንስሳት'),
        QuizInfo(39, 'Wild Animals', 'የዱር እንስሳት'),
        QuizInfo(16, 'Birds', 'ወፎች'),
        QuizInfo(14, 'Sea Animals', 'የውሃ ውስጥ እንስሳት'),
        QuizInfo(34, 'Ethiopian Wildlife', 'የኢትዮጵያ የዱር እንስሳት'),
        QuizInfo(5, 'Water', 'የውሃ አካላት'),
      ],
    ),
    QuizCategory(
      id: 'culture',
      nameEn: 'Ethiopian Culture',
      nameAm: 'የኢትዮጵያ ባህል',
      coverImage: 'items/1/2',
      icon: Icons.local_cafe_rounded,
      colors: [Color(0XFFE0A872), Color(0XFF9A5A2C)],
      quizzes: [
        QuizInfo(1, 'Coffee Ceremony', 'የቡና ሥነ ሥርዓት'),
        QuizInfo(57, 'Ethiopian Food', 'የኢትዮጵያ ምግቦች'),
        QuizInfo(58, 'Holidays', 'በዓላት'),
        QuizInfo(59, 'Traditional Clothes', 'ባህላዊ አልባሳት'),
        QuizInfo(60, 'Home Items', 'ባህላዊ የቤት ዕቃዎች'),
        QuizInfo(50, 'Musicians', 'ሙዚቀኞች'),
      ],
    ),
    QuizCategory(
      id: 'food',
      nameEn: 'Food & Drinks',
      nameAm: 'ምግብና መጠጥ',
      coverImage: 'items/4/4',
      icon: Icons.restaurant_rounded,
      colors: [Color(0XFFFF8A8A), Color(0XFFD9364A)],
      quizzes: [
        QuizInfo(4, 'Fruits', 'ፍራፍሬዎች'),
        QuizInfo(3, 'Vegetables', 'አትክልቶች'),
        QuizInfo(53, 'Grains', 'እህሎች'),
        QuizInfo(7, 'Protein Foods', 'የፕሮቲን ምግቦች'),
        QuizInfo(22, 'Drinks', 'መጠጦች'),
        QuizInfo(26, 'Snacks', 'ፈጣን ምግቦች'),
      ],
    ),
    QuizCategory(
      id: 'me',
      nameEn: 'Me & My Family',
      nameAm: 'እኔና ቤተሰቤ',
      coverImage: 'items/21/4',
      icon: Icons.family_restroom_rounded,
      colors: [Color(0XFFFF9FD2), Color(0XFFD6438E)],
      quizzes: [
        QuizInfo(23, 'Family', 'ቤተሰብ'),
        QuizInfo(18, 'My Face', 'የፊት ክፍሎች'),
        QuizInfo(12, 'My Body', 'የሰውነት ክፍሎች'),
        QuizInfo(21, 'Feelings', 'ስሜቶች'),
        QuizInfo(27, 'Actions', 'ድርጊቶች'),
        QuizInfo(54, 'Jobs', 'ሙያዎች'),
      ],
    ),
    QuizCategory(
      id: 'home',
      nameEn: 'Home & Everyday',
      nameAm: 'ቤትና የዕለት ዕቃዎች',
      coverImage: 'items/2/1',
      icon: Icons.home_rounded,
      colors: [Color(0XFFFFD66B), Color(0XFFD99A0B)],
      quizzes: [
        QuizInfo(2, 'Furniture', 'የቤት ዕቃዎች'),
        QuizInfo(24, 'Clothes', 'አልባሳት'),
        QuizInfo(30, 'Kitchen', 'የወጥ ቤት ዕቃዎች'),
        QuizInfo(36, 'Bathroom', 'የንጽሕና ዕቃዎች'),
        QuizInfo(35, 'Appliances', 'የቤት ኤሌክትሮኒክስ'),
        QuizInfo(41, 'Money', 'ገንዘብ'),
      ],
    ),
    QuizCategory(
      id: 'science',
      nameEn: 'Science & Tech',
      nameAm: 'ሳይንስና ቴክኖሎጂ',
      coverImage: 'items/29/3',
      icon: Icons.rocket_launch_rounded,
      colors: [Color(0XFF7FD3FF), Color(0XFF0071BC)],
      quizzes: [
        QuizInfo(9, 'Transport', 'መጓጓዣዎች'),
        QuizInfo(28, 'Tools', 'መሣሪያዎች'),
        QuizInfo(17, 'Computer', 'ኮምፒውተር'),
        QuizInfo(33, 'Gadgets', 'ጠቃሚ መሣሪያዎች'),
        QuizInfo(37, 'Health', 'ሕክምና'),
        QuizInfo(29, 'Space', 'ጠፈር'),
      ],
    ),
    QuizCategory(
      id: 'fun',
      nameEn: 'Sports, Music & Games',
      nameAm: 'ስፖርት፣ ሙዚቃና ጨዋታ',
      coverImage: 'items/11/4',
      icon: Icons.sports_soccer_rounded,
      colors: [Color(0XFFC5A3FF), Color(0XFF7B3FE4)],
      quizzes: [
        QuizInfo(55, 'Toys', 'መጫወቻዎች'),
        QuizInfo(11, 'Sports', 'ስፖርቶች'),
        QuizInfo(31, 'Indoor Games', 'የቤት ውስጥ ጨዋታዎች'),
        QuizInfo(19, 'Instruments', 'የሙዚቃ መሣሪያዎች'),
        QuizInfo(20, 'Ethiopian Instruments', 'ባህላዊ የሙዚቃ መሣሪያዎች'),
        QuizInfo(45, 'Football Stars', 'የእግር ኳስ ኮከቦች'),
      ],
    ),
    QuizCategory(
      id: 'ethiopia',
      nameEn: 'Ethiopia & the World',
      nameAm: 'ኢትዮጵያና ዓለም',
      coverImage: 'items/25/2',
      icon: Icons.public_rounded,
      colors: [Color(0XFF6FE0C8), Color(0XFF14967E)],
      quizzes: [
        QuizInfo(25, 'Countries', 'አገሮች'),
        QuizInfo(32, 'Landmarks', 'ታሪካዊ ቦታዎች'),
        QuizInfo(56, 'Heritage Sites', 'የዓለም ቅርሶች'),
        QuizInfo(40, 'Natural Wonders', 'የተፈጥሮ ድንቆች'),
        QuizInfo(38, 'Royalty', 'ንጉሣዊ'),
        QuizInfo(48, 'Leaders', 'መሪዎች'),
      ],
    ),
    QuizCategory(
      id: 'people',
      nameEn: 'Famous People',
      nameAm: 'ታዋቂ ሰዎች',
      coverImage: 'items/47/1',
      icon: Icons.star_rounded,
      colors: [Color(0XFFFFA97A), Color(0XFFC4501B)],
      quizzes: [
        QuizInfo(42, "Kids' Favourites", 'የልጆች ተወዳጆች'),
        QuizInfo(47, 'Athletes', 'አትሌቶች'),
        QuizInfo(46, 'Writers', 'ደራሲያን'),
        QuizInfo(49, 'Inspiring People', 'አርአያ ሰዎች'),
        QuizInfo(43, 'Ethiopian Business', 'የኢትዮጵያ ባለሀብቶች'),
        QuizInfo(44, 'World Business', 'የዓለም ባለሀብቶች'),
      ],
    ),
  ];

  static final Map<int, QuizCategory> _categoryByLevel = {
    for (final c in categories)
      for (final q in c.quizzes) q.level: c,
  };

  static QuizCategory? categoryOf(int level) => _categoryByLevel[level];

  static QuizInfo? quiz(int level) {
    final QuizCategory? c = categoryOf(level);
    if (c == null) return null;
    for (final q in c.quizzes) {
      if (q.level == level) return q;
    }
    return null;
  }

  /// Topic name for the top bar, e.g. "Fruits".
  static String? titleFor(int level, String languageCode) =>
      quiz(level)?.nameFor(languageCode);

  /// The quiz after [level] within the same category, or null if [level] is
  /// the last one, which hides "Play Next" on the result screen.
  static int? nextLevelAfter(int level) {
    final QuizCategory? c = categoryOf(level);
    if (c == null) return null;
    final int i = c.quizzes.indexWhere((q) => q.level == level);
    if (i < 0 || i + 1 >= c.quizzes.length) return null;
    return c.quizzes[i + 1].level;
  }

  /// Asserts that every level 1..[totalLevels] is in exactly one category.
  static bool debugValidate(int totalLevels) {
    final List<int> all = [
      for (final c in categories) ...c.quizzes.map((q) => q.level),
    ];
    assert(
      all.length == all.toSet().length,
      'QuizCatalog: a level is listed in more than one category',
    );
    final missing = [
      for (int l = 1; l <= totalLevels; l++)
        if (!_categoryByLevel.containsKey(l)) l,
    ];
    assert(missing.isEmpty, 'QuizCatalog: levels $missing have no category');
    return true;
  }
}

/// A star counts once the player has earned at least one star (score 0.2+),
/// matching the level tile artwork.
const double kQuizDoneScore = 0.2;
