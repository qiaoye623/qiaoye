import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/zodiac_map.dart';

class DrawData {
  final String period;
  final List<String> numbers;
  final String special;

  const DrawData({
    required this.period,
    required this.numbers,
    required this.special,
  });

  String get drawInfo {
    final buf = StringBuffer('$period\n');
    for (int i = 0; i < numbers.length; i++) {
      if (i > 0 && i % 4 == 0) buf.writeln();
      final n = int.tryParse(numbers[i]) ?? 0;
      final z = ZodiacMap.getZodiac(n);
      final w = ZodiacMap.getWave(n);
      buf.write('${numbers[i]}($z-$w) ');
    }
    buf.writeln();
    final sn = int.tryParse(special) ?? 0;
    final sz = ZodiacMap.getZodiac(sn);
    final sw = ZodiacMap.getWave(sn);
    buf.write('$special($sz-$sw) 特码：$special');
    return buf.toString();
  }
}

class LotteryFetcher {
  /// 只使用本地 Python 代理，没有 CWL 或其他回退
  static Future<DrawData?> fetchDrawData() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3002/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[LotteryFetcher] Proxy returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map) return null;

      final period = data['period'] as String?;
      final numbers = data['numbers'] as List?;
      final special = data['special'] as String?;

      if (period == null || numbers == null || special == null) return null;
      if (numbers.length < 6) return null;

      debugPrint('[LotteryFetcher] OK: $period 特码$special');
      return DrawData(
        period: period,
        numbers: numbers.cast<String>(),
        special: special,
      );
    } catch (e) {
      debugPrint('[LotteryFetcher] Error: $e');
      return null;
    }
  }
}
