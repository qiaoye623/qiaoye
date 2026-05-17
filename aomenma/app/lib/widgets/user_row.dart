import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/zodiac_map.dart';
import '../constants/theme.dart';
import '../models/user_bet.dart';
import '../providers/app_state.dart';

class UserRow extends StatelessWidget {
  final UserBet user;
  const UserRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final drawNo = context.select<AppState, String>((s) => s.config.drawNo);
    final drawNumbers = context.select<AppState, List<String>>((s) => s.config.drawNumbers);
    final target = drawNo.padLeft(2, '0');
    final dn = int.tryParse(drawNo) ?? 0;
    final allNums = <int>{dn};
    for (final ns in drawNumbers) {
      final n = int.tryParse(ns);
      if (n != null) allNums.add(n);
    }

    final payAmount = user.winMoney - user.totalBet;
    final payColor = payAmount > 0
        ? AppTheme.danger
        : (payAmount < 0 ? AppTheme.success : AppTheme.textSecondary);
    final hasPlay = user.playBets.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.shadow,
      ),
      padding: const EdgeInsets.all(AppTheme.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                user.name.isNotEmpty ? user.name : user.id,
                style: const TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              if (user.name.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  user.id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
              if (user.totalBet > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '投注：¥${user.totalBet.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppTheme.helperSize,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.danger),
                  onPressed: () =>
                      context.read<AppState>().removeUser(user.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildCombinedRow(user, target, dn, allNums),
          const SizedBox(height: 4),
          Text(
            '中奖：¥${user.winMoney.toStringAsFixed(0)} | 返水：¥${user.rebate.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: AppTheme.helperSize,
              color: user.winMoney > 0
                  ? AppTheme.success
                  : AppTheme.textGray,
              fontWeight:
                  user.winMoney > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '应付：¥${payAmount.toStringAsFixed(0)} | '
            '特码中：${user.winCodeCount}注 '
            '生肖中：${user.winZodiacCount}注'
            '${hasPlay ? ' 玩法中：${user.playWinCount}注' : ''}',
            style: TextStyle(
              fontSize: AppTheme.helperSize,
              color: payColor,
              fontWeight:
                  payAmount != 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 横向合并显示特码/生肖/玩法
  Widget _buildCombinedRow(
      UserBet user, String target, int dn, Set<int> allNums) {
    final spans = <InlineSpan>[];
    void addCategory(
        String label, String raw, Map<String, bool> winMap) {
      if (raw.isEmpty) return;
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(
          text: '  ',
          style: TextStyle(fontSize: 12, color: AppTheme.textGray),
        ));
      }
      spans.add(TextSpan(
        text: '$label：',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ));
      final items = raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (int i = 0; i < items.length; i++) {
        if (i > 0) spans.add(const TextSpan(text: ', '));
        final item = items[i];
        final key = item.split('(')[0].trim();
        final isWin = winMap[key] ?? false;
        spans.add(TextSpan(
          text: '$item${isWin ? ' ✓' : ' ✗'}',
          style: TextStyle(
            fontSize: 12,
            color: isWin ? AppTheme.success : AppTheme.textPrimary,
            fontWeight: isWin ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      }
    }

    addCategory('特码', user.codeBets, _codeWinMap(user.codeBets, target));
    addCategory('生肖', user.zodiacBets,
        _zodiacWinMap(user.zodiacBets, allNums));
    addCategory('玩法', user.playBets,
        _playWinMap(user.playBets, dn, allNums));

    if (spans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(text: TextSpan(children: spans)),
    );
  }

  /// 特码中奖映射 { "04": true/false, ... }
  Map<String, bool> _codeWinMap(String codeBets, String target) {
    if (target == '00') return {};
    final map = <String, bool>{};
    for (final s in codeBets.split(',')) {
      final t = s.trim();
      if (t.isEmpty) continue;
      final num = t.split('(')[0].trim();
      map[num] = num == target;
    }
    return map;
  }

  /// 生肖中奖映射 { "兔": true/false, ... }
  Map<String, bool> _zodiacWinMap(String zodiacBets, Set<int> allNums) {
    if (allNums.isEmpty) return {};
    final map = <String, bool>{};
    for (final s in zodiacBets.split(',')) {
      final t = s.trim();
      if (t.isEmpty) continue;
      final z = t.split('(')[0].trim();
      map[z] = allNums.any((n) => ZodiacMap.getZodiac(n) == z);
    }
    return map;
  }

  /// 玩法中奖映射 { "鸡兔二友": true/false, ... }
  Map<String, bool> _playWinMap(
      String playBets, int dn, Set<int> allNums) {
    if (allNums.isEmpty) return {};
    final map = <String, bool>{};
    final dz = ZodiacMap.getZodiac(dn);
    final dTail = dn % 10;

    for (final s in playBets.split(',')) {
      final t = s.trim();
      if (t.isEmpty) continue;
      final key = t.split('(')[0].trim();
      bool won = false;

      // 二友/三友/四友/五友（可选带马）
      var m = RegExp(
              r'^([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)(二友|三友|四友|五友)(带马)?$')
          .firstMatch(key);
      if (m != null) {
        final withHorse = m.group(3) != null;
        final allPresent = m.group(1)!.split('').every(
            (z) => allNums.any((n) => ZodiacMap.getZodiac(n) == z));
        final horseOk = !withHorse ||
            allNums.any((n) => ZodiacMap.getZodiac(n) == '马');
        if (allPresent && horseOk) won = true;
      }

      // 特单/特双/单双/双单
      if (!won) {
        if ((key == '特单' || key == '单双') && dn % 2 == 1) won = true;
        if ((key == '特双' || key == '双单') && dn % 2 == 0) won = true;
      }

      // 特大/特小
      if (!won) {
        if (key == '特大' && dn > 24) won = true;
        if (key == '特小' && dn <= 24) won = true;
      }

      // 波色
      if (!won) {
        final w = ZodiacMap.getWave(dn);
        if ((key == '红波' && w == '红') ||
            (key == '蓝波' && w == '蓝') ||
            (key == '绿波' && w == '绿') ||
            (key == '蓝绿波' && (w == '蓝' || w == '绿'))) {
          won = true;
        }
      }

      // 本肖马
      if (!won && key == '本肖马' && dz == '马') won = true;

      // 0尾
      if (!won && key == '0尾' && dTail == 0) won = true;

      // 独平NN
      if (!won) {
        m = RegExp(r'^独平(\d{2})$').firstMatch(key);
        if (m != null) {
          final num = int.parse(m.group(1)!);
          final flatNums = <int>{...allNums}..remove(dn);
          won = flatNums.contains(num);
        }
      }

      // 尾数N
      if (!won) {
        m = RegExp(r'^尾数(\d)$').firstMatch(key);
        if (m != null && dTail == int.parse(m.group(1)!)) won = true;
      }

      // 二中二/连特（只判断平码，不含特码）
      if (!won) {
        m = RegExp(r'^(二中二|连特)(\d{2})\s+(\d{2})$').firstMatch(key);
        final flatNums = Set<int>.from(allNums)..remove(dn);
        if (m != null &&
            flatNums.contains(int.parse(m.group(2)!)) &&
            flatNums.contains(int.parse(m.group(3)!))) {
          won = true;
        }
      }

      // 五不中～十不中
      if (!won) {
        m = RegExp(r'^((?:五|六|七|八|九|十)不中)((?:\d{2}\s+)*\d{2})$')
            .firstMatch(key);
        if (m != null) {
          final nums =
              m.group(2)!.split(RegExp(r'\s+')).map(int.parse).toSet();
          won = nums.every((n) => !allNums.contains(n));
        }
      }

      // 六肖中特/五肖中特
      if (!won) {
        m = RegExp(r'^((?:六|五)肖中特)([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)$')
            .firstMatch(key);
        if (m != null && m.group(2)!.contains(dz)) won = true;
      }

      // 连尾（特码尾数在固定区间内）
      if (!won) {
        const tailRanges = {
          '二连尾': {0, 1},
          '三连尾': {0, 1, 2},
          '四连尾': {0, 1, 2, 3},
        };
        final range = tailRanges[key];
        if (range != null && range.contains(dTail)) won = true;
      }

      map[key] = won;
    }

    return map;
  }
}
