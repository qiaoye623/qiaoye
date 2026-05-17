class ZodiacMap {
  /// 生肖 → 号码（修正版最终正确数据）
  static const Map<String, List<int>> zodiacToNums = {
    '马': [1, 13, 25, 37, 49],
    '蛇': [2, 14, 26, 38],
    '龙': [3, 15, 27, 39],
    '兔': [4, 16, 28, 40],
    '虎': [5, 17, 29, 41],
    '牛': [6, 18, 30, 42],
    '鼠': [7, 19, 31, 43],
    '猪': [8, 20, 32, 44],
    '狗': [9, 21, 33, 45],
    '鸡': [10, 22, 34, 46],
    '猴': [11, 23, 35, 47],
    '羊': [12, 24, 36, 48],
  };

  static const List<String> allZodiacs = [
    '马', '蛇', '龙', '兔', '虎',
    '牛', '鼠', '猪', '狗', '鸡',
    '猴', '羊',
  ];

  /// 用户输入时仍然按传统顺序显示
  static const List<String> validZodiacsForInput = [
    '鼠', '牛', '虎', '兔', '龙', '蛇',
    '马', '羊', '猴', '鸡', '狗', '猪',
  ];

  static final Map<int, String> _numToZodiac = () {
    final map = <int, String>{};
    for (final entry in zodiacToNums.entries) {
      for (final num in entry.value) {
        map[num] = entry.key;
      }
    }
    return map;
  }();

  static String getZodiac(int num) => _numToZodiac[num] ?? '';

  static bool isValidZodiac(String s) => validZodiacsForInput.contains(s);

  /// 波色数据
  static const List<int> redWave = [
    1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30, 34, 35, 40, 45, 46,
  ];
  static const List<int> blueWave = [
    3, 4, 9, 10, 14, 15, 20, 25, 26, 31, 36, 37, 41, 42, 47, 48,
  ];
  static const List<int> greenWave = [
    5, 6, 11, 16, 17, 21, 22, 27, 28, 32, 33, 38, 39, 43, 44, 49,
  ];

  /// 获取号码的波色，返回 '红'/'蓝'/'绿' 或空字符串
  static String getWave(int num) {
    if (redWave.contains(num)) return '红';
    if (blueWave.contains(num)) return '蓝';
    if (greenWave.contains(num)) return '绿';
    return '';
  }
}
