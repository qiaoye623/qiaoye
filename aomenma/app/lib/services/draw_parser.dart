import '../models/draw_ball.dart';

class DrawParser {
  /// 解析 drawInfo 字符串为结构化 DrawResult
  ///
  /// 输入格式示例：
  ///   第2026052期
  ///   01(马-金) 07(鼠-水) 13(马-金) 19(鼠-水)
  ///   25(马-金) 37(马-金) 43(鼠-水)
  ///   特码：07
  static DrawResult parse(String raw) {
    if (raw.isEmpty) return const DrawResult();

    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return const DrawResult();

    final period = lines.first;
    String specialNumber = '';

    // 提取特码
    final specialMatch = RegExp(r'特码[：:](\d{1,2})').firstMatch(raw);
    if (specialMatch != null) {
      specialNumber = specialMatch.group(1)!.padLeft(2, '0');
    }

    final balls = <DrawBall>[];

    // 逐行解析号码
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('特码')) continue;

      // 匹配 "01(马-金)" 格式
      final ballMatches = RegExp(r'(\d{1,2})\(([一-鿿]+)-([一-鿿]+)\)')
          .allMatches(line);
      for (final m in ballMatches) {
        final num = m.group(1)!.padLeft(2, '0');
        balls.add(DrawBall(
          number: num,
          zodiac: m.group(2)!,
          element: m.group(3)!,
          isSpecial: num == specialNumber,
        ));
      }
    }

    return DrawResult(
      period: period,
      balls: balls,
      specialNumber: specialNumber,
    );
  }
}
