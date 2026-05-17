import 'dart:convert';
import 'lottery_fetcher.dart';

class LotteryParser {
  /// 根据 URL 类型选择对应解析器
  static DrawData? parse(String body, String url) {
    if (url.contains('cwl.gov.cn')) return _parseCwlJson(body);
    if (url.contains('hkjc.com')) return _parseHkjcHtml(body);
    if (url.contains('lottery.gov.cn')) return _parseGovHtml(body);
    return _parseGeneric(body);
  }

  /// 中国福利彩票 JSON 接口
  static DrawData? _parseCwlJson(String body) {
    try {
      final data = jsonDecode(body);
      if (data is! Map || data['result'] is! List) return null;
      final list = data['result'] as List;
      if (list.isEmpty) return null;
      final first = list[0] as Map<String, dynamic>;

      final name = first['name'] as String? ?? '';
      final code = first['code'] as String?;
      if (code == null) return null;

      final nums = code.trim().split(RegExp(r'\s+'));
      if (nums.length < 6) return null;

      final period = name.replaceAll('期', '');
      return DrawData(
        period: '第$period期',
        numbers: nums.sublist(0, 6),
        special: nums.length > 6 ? nums[6] : nums[5],
      );
    } catch (_) {
      return null;
    }
  }

  /// 香港赛马会六合彩 HTML
  static DrawData? _parseHkjcHtml(String body) {
    try {
      // 尝试提取期号
      final periodMatch = RegExp(r'第\s*(\d+)\s*期').firstMatch(body);
      final period = periodMatch != null
          ? '第${periodMatch.group(1)}期'
          : '最新一期';

      // 提取所有两位数号码 (01-49)
      final nums = RegExp(r'\b(0[1-9]|[1-4]\d)\b')
          .allMatches(body)
          .map((m) => m.group(1)!)
          .toList();

      if (nums.length < 7) return null;

      return DrawData(
        period: period,
        numbers: nums.sublist(0, 6),
        special: nums[6],
      );
    } catch (_) {
      return null;
    }
  }

  /// 中国体彩网 HTML
  static DrawData? _parseGovHtml(String body) {
    try {
      final periodMatch = RegExp(r'第(\d+)期').firstMatch(body);
      final period = periodMatch != null
          ? '第${periodMatch.group(1)}期'
          : '最新期';

      final nums = RegExp(r'\b(0[1-9]|[1-4]\d|4[0-9])\b')
          .allMatches(body)
          .map((m) => m.group(1)!)
          .where((n) {
            final v = int.parse(n);
            return v >= 1 && v <= 49;
          })
          .toList();

      if (nums.length < 7) return null;

      return DrawData(
        period: period,
        numbers: nums.sublist(0, 6),
        special: nums[6],
      );
    } catch (_) {
      return null;
    }
  }

  /// 通用 HTML/文本解析
  static DrawData? _parseGeneric(String body) {
    try {
      // 尝试匹配期号
      String period;
      final p1 = RegExp(r'第(\d+)期').firstMatch(body);
      final p2 = RegExp(r'(\d{5,6})期').firstMatch(body);
      if (p1 != null) {
        period = '第${p1.group(1)}期';
      } else if (p2 != null) {
        period = '第${p2.group(1)}期';
      } else {
        period = '最新开奖';
      }

      // 提取 01-49 范围内的两位数
      final nums = RegExp(r'\b(0[1-9]|[1-4]\d|49)\b')
          .allMatches(body)
          .map((m) => m.group(1)!)
          .where((n) {
            final v = int.tryParse(n);
            return v != null && v >= 1 && v <= 49;
          })
          .toList();

      // 去重
      final unique = nums.toSet().toList();
      if (unique.length < 7) return null;

      return DrawData(
        period: period,
        numbers: unique.sublist(0, 6),
        special: unique[6],
      );
    } catch (_) {
      return null;
    }
  }
}
