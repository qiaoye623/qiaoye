import '../constants/zodiac_map.dart';

class BetParseResult {
  final Map<String, double> codeAmounts;
  final Map<String, double> zodiacAmounts;
  final Map<String, double> playAmounts;
  final double totalAmount;
  final String codeDisplay;
  final String zodiacDisplay;
  final String playDisplay;
  final String error;

  const BetParseResult({
    this.codeAmounts = const {},
    this.zodiacAmounts = const {},
    this.playAmounts = const {},
    this.totalAmount = 0,
    this.codeDisplay = '',
    this.zodiacDisplay = '',
    this.playDisplay = '',
    this.error = '',
  });

  bool get hasError => error.isNotEmpty;
  bool get isEmpty =>
      codeAmounts.isEmpty &&
      zodiacAmounts.isEmpty &&
      playAmounts.isEmpty &&
      error.isEmpty;

  static const empty = BetParseResult();
}

class BetParser {
  /// 主入口：解析用户粘贴的投注文本
  static BetParseResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return BetParseResult.empty;

    final codeAmounts = <String, double>{};
    final zodiacAmounts = <String, double>{};
    final playAmounts = <String, double>{};

    // 统一分隔符：空格、中文逗号、点、减号、斜杠 → 英文逗号
    // 先按换行拆分，避免 \s 吞掉换行符导致多行合并
    final lines = trimmed.split('\n').map((l) => l.trim()
        .replaceAll(RegExp(r'[，、.\-/\s]+'), ',')
        .replaceAll(RegExp(r',+'), ',')
    ).where((l) => l.isNotEmpty).toList();
    bool anyHandled = false;

    for (final line in lines) {

      // 依次尝试各格式
      if (_tryOldZodiac(line, codeAmounts, zodiacAmounts)) {
        anyHandled = true;
        continue;
      }

      if (_tryPingXiao(line, codeAmounts, zodiacAmounts)) {
        anyHandled = true;
        continue;
      }

      if (_tryNumber(line, codeAmounts)) {
        anyHandled = true;
        continue;
      }

      if (_tryFriends(line, playAmounts)) {
        anyHandled = true;
        continue;
      }

      if (_tryFlatBet(line, playAmounts)) {
        anyHandled = true;
        continue;
      }
    }

    // 如果都没有匹配到，尝试旧解析器作为兜底
    if (!anyHandled) {
      final legacy = _legacyParse(trimmed);
      return BetParseResult(
        codeAmounts: legacy.codeAmounts,
        zodiacAmounts: legacy.zodiacAmounts,
        totalAmount: legacy.totalAmount,
        codeDisplay: legacy.codeDisplay,
        zodiacDisplay: legacy.zodiacDisplay,
        error: legacy.error,
      );
    }

    final total = codeAmounts.values.fold(0.0, (a, b) => a + b) +
        zodiacAmounts.values.fold(0.0, (a, b) => a + b) +
        playAmounts.values.fold(0.0, (a, b) => a + b);

    final codeDisplay = codeAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');
    final zodiacDisplay = zodiacAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');
    final playDisplay = playAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');

    return BetParseResult(
      codeAmounts: codeAmounts,
      zodiacAmounts: zodiacAmounts,
      playAmounts: playAmounts,
      totalAmount: total,
      codeDisplay: codeDisplay,
      zodiacDisplay: zodiacDisplay,
      playDisplay: playDisplay,
      error: codeAmounts.isEmpty && zodiacAmounts.isEmpty && playAmounts.isEmpty ? '未识别到有效投注' : '',
    );
  }

  /// 解析金额值，支持阿拉伯数字和中文数字
  static double _parseAmount(String text) {
    final ar = double.tryParse(text);
    if (ar != null) return ar;
    return _parseChineseNum(text).toDouble();
  }

  /// 中文数字转整数（五十→50，二十→20，一百→100）
  static int _parseChineseNum(String text) {
    const digits = {
      '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
    };
    const scales = {
      '十': 10, '百': 100, '千': 1000,
    };
    int result = 0, current = 0;
    for (final char in text.split('')) {
      if (digits.containsKey(char)) {
        current = digits[char]!;
      } else if (scales.containsKey(char)) {
        if (current == 0) current = 1;
        result += current * scales[char]!;
        current = 0;
      }
    }
    return result + current;
  }

  /// 格式1：纯号码 "01,02,03各20" 或 "特04-40各五十"
  /// 支持一行多个组合： "16-28各二十特04-40各五十"
  static bool _tryNumber(
      String line, Map<String, double> codeAmounts) {
    final pattern = RegExp(
        r'(\d{1,2}(?:[,，]\d{1,2})*)各(\d+(?:\.\d+)?|[零一二三四五六七八九十百千]+)');
    final matches = pattern.allMatches(line);

    if (matches.isEmpty) return false;

    bool handled = false;
    for (final m in matches) {
      final perAmount = _parseAmount(m.group(2)!);
      if (perAmount <= 0) continue;

      for (final numStr in m.group(1)!.split(RegExp(r'[,，]'))) {
        final n = int.tryParse(numStr.trim());
        if (n != null && n >= 1 && n <= 49) {
          final key = n.toString().padLeft(2, '0');
          codeAmounts[key] = (codeAmounts[key] ?? 0) + perAmount;
          handled = true;
        }
      }
    }
    return handled;
  }

  /// 格式2：传统生肖格式
  ///   "鼠肖各50"、"虎兔两肖各100"、"包马肖50"、"平肖买牛/羊各30"
  static bool _tryOldZodiac(
      String line, Map<String, double> codeAmounts, Map<String, double> zodiacAmounts) {
    final perMatch = RegExp(r'各(\d+(?:\.\d+)?|[零一二三四五六七八九十百千]+)').firstMatch(line);
    if (perMatch == null) return false;
    final perAmount = _parseAmount(perMatch.group(1)!);

    final foundZodiacs = <String>{};
    // 平肖的生肖（只记生肖，不拆分号码）
    final pingZodiacs = <String>{};

    // "平肖买X/Y" 或 "平肖买X" — 只记生肖不拆分号码
    var text = line.replaceAllMapped(
        RegExp(r'平肖买?([鼠牛虎兔龙蛇马羊猴鸡狗猪]+(?:[,，][鼠牛虎兔龙蛇马羊猴鸡狗猪]+)*)'), (m) {
      for (final c in m.group(1)!.split(RegExp(r'[,，]'))) {
        if (c.isNotEmpty) pingZodiacs.add(c);
      }
      return '';
    });

    // "包X肖"
    text = text.replaceAllMapped(
        RegExp(r'包([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)肖'), (m) {
      for (final c in (m.group(1) ?? '').split('')) foundZodiacs.add(c);
      return '';
    });

    // "XY两肖"
    text = text.replaceAllMapped(
        RegExp(r'([鼠牛虎兔龙蛇马羊猴鸡狗猪])([鼠牛虎兔龙蛇马羊猴鸡狗猪])两肖'),
        (m) {
      foundZodiacs.add(m.group(1)!);
      foundZodiacs.add(m.group(2)!);
      return '';
    });

    // "X肖"
    text = text.replaceAllMapped(
        RegExp(r'([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)肖'), (m) {
      for (final c in (m.group(1) ?? '').split('')) foundZodiacs.add(c);
      return '';
    });

    // 直接出现的生肖字
    for (final z in ZodiacMap.validZodiacsForInput) {
      if (text.contains(z)) {
        foundZodiacs.add(z);
      }
    }

    if (foundZodiacs.isEmpty && pingZodiacs.isEmpty) return false;

    // 特肖 → 拆分为号码（用于特码匹配）
    for (final z in foundZodiacs) {
      zodiacAmounts[z] = (zodiacAmounts[z] ?? 0) + perAmount;
      final nums = ZodiacMap.zodiacToNums[z];
      if (nums != null) {
        for (final n in nums) {
          final key = n.toString().padLeft(2, '0');
          codeAmounts[key] = (codeAmounts[key] ?? 0) + perAmount;
        }
      }
    }
    // 平肖 → 只记生肖不拆号码
    for (final z in pingZodiacs) {
      zodiacAmounts[z] = (zodiacAmounts[z] ?? 0) + perAmount;
    }
    return true;
  }

  /// 格式3：平肖/澳平肖 "鼠平肖100" → 只记生肖投注，不拆分号码
  static bool _tryPingXiao(
      String line, Map<String, double> codeAmounts, Map<String, double> zodiacAmounts) {
    final mat = RegExp(r'(?:澳平肖|平肖)?([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)平?(\d+)')
        .firstMatch(line);
    if (mat == null) return false;

    final z = mat.group(1)!;
    final allAmt = double.parse(mat.group(2)!);
    zodiacAmounts[z] = (zodiacAmounts[z] ?? 0) + allAmt;
    return true;
  }

  /// 格式4：二友/三友/四友/五友 "鼠虎二友100" / "鸡兔二友带马300"
  static bool _tryFriends(
      String line, Map<String, double> playAmounts) {
    // 先尝试带马格式: "鸡兔二友带马300"
    var mat = RegExp(
            r'([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)(二友|三友|四友|五友)带马(\d+)')
        .firstMatch(line);
    if (mat != null) {
      final playName = '${mat.group(1)}${mat.group(2)}带马';
      final pay = double.parse(mat.group(3)!);
      playAmounts[playName] = (playAmounts[playName] ?? 0) + pay;
      return true;
    }

    // 标准格式: "鼠虎二友100"
    mat = RegExp(
            r'([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)(二友|三友|四友|五友)(\d+)')
        .firstMatch(line);
    if (mat == null) return false;

    final playName = '${mat.group(1)}${mat.group(2)}';
    final pay = double.parse(mat.group(3)!);
    playAmounts[playName] = (playAmounts[playName] ?? 0) + pay;
    return true;
  }

  /// 格式5：固定玩法 — 先匹配带选区信息的格式，再匹配纯金额格式
  static bool _tryFlatBet(String line, Map<String, double> playAmounts) {
    // === 带选区信息的玩法（选区编码在 key 中，用于算赢）===

    // 1. 独平 + 号码 + 金额: "独平07 50" / "独平07-50"
    var mat = RegExp(r'^独平(\d{1,2})\s+(\d+)$').firstMatch(line);
    mat ??=
        RegExp(r'^独平(\d{1,2})\s*[-–，,/]\s*(\d+)$').firstMatch(line);
    if (mat != null) {
      playAmounts['独平${mat.group(1)!.padLeft(2, '0')}'] =
          double.parse(mat.group(2)!);
      return true;
    }

    // 2. 尾数 + 数字 + 金额: "尾数8 50"
    mat = RegExp(r'^尾数(\d)\s+(\d+)$').firstMatch(line);
    if (mat != null) {
      playAmounts['尾数${mat.group(1)}'] = double.parse(mat.group(2)!);
      return true;
    }

    // 3. 二中二/连特 A B 金额: "二中二09 18 50"
    mat = RegExp(r'^(二中二|连特)(\d{1,2})\s+(\d{1,2})\s+(\d+)$')
        .firstMatch(line);
    if (mat != null) {
      playAmounts[
          '${mat.group(1)}${mat.group(2)!.padLeft(2, '0')} ${mat.group(3)!.padLeft(2, '0')}'] =
          double.parse(mat.group(4)!);
      return true;
    }

    // 4. 五不中～十不中 + 号码 + 金额: "五不中01 05 12 19 33 50"
    mat = RegExp(r'^((?:五|六|七|八|九|十)不中)((?:\d{1,2}\s+)+)(\d+)$')
        .firstMatch(line);
    if (mat != null) {
      final nums = mat.group(2)!
          .trim()
          .split(RegExp(r'\s+'))
          .map((n) => n.padLeft(2, '0'))
          .join(' ');
      playAmounts['${mat.group(1)}$nums'] = double.parse(mat.group(3)!);
      return true;
    }

    // 5. 六肖中特/五肖中特 + 生肖 + 金额: "六肖中特鼠虎龙 50"
    mat = RegExp(r'^((?:六|五)肖中特)([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)\s+(\d+)$')
        .firstMatch(line);
    if (mat != null) {
      playAmounts['${mat.group(1)}${mat.group(2)}'] =
          double.parse(mat.group(3)!);
      return true;
    }

    // === 简单玩法（只有金额，无选区信息）===
    // 本肖马, 特大小, 六肖中特, 红波, 二中二, 独平, 五不中, 0尾, 尾数, 二连尾
    // 注意：带选区的格式已在上面优先匹配，这里只处理纯 "玩法+金额" 格式
    if (RegExp(r'^(?:本肖马|特大|特小|特单|特双|单双|双单|'
            r'六肖中特|五肖中特|红波|蓝波|绿波|蓝绿波|'
            r'二中二|连特|独平|'
            r'五不中|六不中|七不中|八不中|九不中|十不中|'
            r'0尾|尾数|二连尾|三连尾|四连尾)(\d+)$')
        .hasMatch(line)) {
      // 用原简单模式逐一匹配
      for (final pattern in _flatBetPatterns) {
        mat = pattern.firstMatch(line);
        if (mat != null) {
          final full = mat.group(0)!;
          final amtStr = mat.group(1)!;
          final playName = full.substring(0, full.length - amtStr.length);
          final amt = double.parse(amtStr);
          playAmounts[playName] = (playAmounts[playName] ?? 0) + amt;
          return true;
        }
      }
    }
    return false;
  }

  /// 简单模式列表（纯金额格式兜底）
  static final List<RegExp> _flatBetPatterns = [
    RegExp(r'^(?:二中二|连特)(\d+)$'),
    RegExp(r'^(?:特大|特小|特单|特双|单双|双单)(\d+)$'),
    RegExp(r'^(?:六肖中特|五肖中特)(\d+)$'),
    RegExp(r'^(?:红波|蓝波|绿波|蓝绿波)(\d+)$'),
    RegExp(r'^独平(\d+)$'),
    RegExp(r'^(?:五不中|六不中|七不中|八不中|九不中|十不中)(\d+)$'),
    RegExp(r'^(?:0尾|尾数)(\d+)$'),
    RegExp(r'^(?:二连尾|三连尾|四连尾)(\d+)$'),
    RegExp(r'^本肖马(\d+)$'),
  ];

  // ========== 旧解析器兜底（保持向后兼容） ==========

  static BetParseResult _legacyParse(String input) {
    double perAmount = 0;
    String rest = input;
    final perMatch = RegExp(r'各(\d+(?:\.\d+)?|[零一二三四五六七八九十百千]+)').firstMatch(input);
    if (perMatch != null) {
      perAmount = _parseAmount(perMatch.group(1)!);
      rest = input.replaceAll(RegExp(r'各\d+(?:\.\d+)?|[零一二三四五六七八九十百千]+'), '').trim();
    }

    final hasZodiacKeyword =
        RegExp(r'[鼠牛虎兔龙蛇马羊猴鸡狗猪]|肖|包').hasMatch(rest);

    if (hasZodiacKeyword) {
      return _legacyParseZodiac(rest, perAmount, input);
    } else {
      return _legacyParseNumbers(rest, perAmount, input);
    }
  }

  static BetParseResult _legacyParseNumbers(
      String rest, double perAmount, String raw) {
    final amounts = <String, double>{};
    final seen = <String>{};

    final parts = rest
        .split(RegExp(r'[/\-，.\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num != null && num >= 1 && num <= 49) {
        final key = num.toString().padLeft(2, '0');
        if (!seen.contains(key)) {
          seen.add(key);
          amounts[key] = perAmount;
        }
      }
    }

    final total = amounts.values.fold(0.0, (a, b) => a + b);
    final display = amounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');

    return BetParseResult(
      codeAmounts: amounts,
      totalAmount: total,
      codeDisplay: display,
      error: amounts.isEmpty ? '未识别到有效号码' : '',
    );
  }

  static BetParseResult _legacyParseZodiac(
      String rest, double perAmount, String raw) {
    final codeAmounts = <String, double>{};
    final zodiacAmounts = <String, double>{};
    final foundZodiacs = <String>{};
    final pingZodiacs = <String>{};

    var text = rest.replaceAllMapped(
        RegExp(
            r'平肖买?([鼠牛虎兔龙蛇马羊猴鸡狗猪]+(?:[,，/、][鼠牛虎兔龙蛇马羊猴鸡狗猪]+)*)'),
        (m) {
      for (final c in m.group(1)!.split(RegExp(r'[,，/、]'))) {
        if (c.isNotEmpty) pingZodiacs.add(c);
      }
      return '';
    });

    text = text.replaceAllMapped(
        RegExp(r'包([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)肖'), (m) {
      for (final c in (m.group(1) ?? '').split('')) foundZodiacs.add(c);
      return '';
    });

    text = text.replaceAllMapped(
        RegExp(
            r'([鼠牛虎兔龙蛇马羊猴鸡狗猪])([鼠牛虎兔龙蛇马羊猴鸡狗猪])两肖'),
        (m) {
      foundZodiacs.add(m.group(1)!);
      foundZodiacs.add(m.group(2)!);
      return '';
    });

    text = text.replaceAllMapped(
        RegExp(r'([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)肖'), (m) {
      for (final c in (m.group(1) ?? '').split('')) foundZodiacs.add(c);
      return '';
    });

    for (final z in ZodiacMap.validZodiacsForInput) {
      if (text.contains(z)) foundZodiacs.add(z);
    }

    if (foundZodiacs.isEmpty && pingZodiacs.isEmpty) {
      return BetParseResult(error: '未识别到有效生肖');
    }

    // 特肖 → 拆号码
    for (final z in foundZodiacs) {
      final nums = ZodiacMap.zodiacToNums[z];
      if (nums != null) {
        zodiacAmounts[z] = (zodiacAmounts[z] ?? 0) + perAmount;
        for (final n in nums) {
          final key = n.toString().padLeft(2, '0');
          codeAmounts[key] = (codeAmounts[key] ?? 0) + perAmount;
        }
      }
    }
    // 平肖 → 只记生肖
    for (final z in pingZodiacs) {
      zodiacAmounts[z] = (zodiacAmounts[z] ?? 0) + perAmount;
    }

    final total = codeAmounts.values.fold(0.0, (a, b) => a + b) +
        zodiacAmounts.values.fold(0.0, (a, b) => a + b);
    final zDisplay = zodiacAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');
    final cDisplay = codeAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');

    return BetParseResult(
      codeAmounts: codeAmounts,
      zodiacAmounts: zodiacAmounts,
      totalAmount: total,
      codeDisplay: cDisplay,
      zodiacDisplay: zDisplay,
      error: foundZodiacs.isEmpty && pingZodiacs.isEmpty ? '未识别到有效生肖' : '',
    );
  }
}
