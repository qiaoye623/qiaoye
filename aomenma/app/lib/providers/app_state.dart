import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../constants/zodiac_map.dart';
import '../models/date_config.dart';
import '../models/rate_config.dart';
import '../models/user_bet.dart';
import '../models/daily_summary.dart';
import '../services/bet_parser.dart';
import '../services/lottery_fetcher.dart';

class AppState extends ChangeNotifier {
  static const _cutoffHour = 21;
  static const _cutoffMinute = 35;

  String _currentDate = _formatDate(DateTime.now());
  DateConfig _config = DateConfig();
  List<UserBet> _users = [];
  DailySummary _summary = DailySummary();
  bool _isConfigExpanded = true;
  bool _showFixFields = false;
  String _lotteryStatus = 'none';
  String _lotteryErrorMsg = '';
  int _userCounter = 0;

  /// 按日期存储的历史数据快照
  final Map<String, _DaySnapshot> _savedDays = {};
  bool _loaded = false;

  String get currentDate => _currentDate;
  DateConfig get config => _config;
  List<UserBet> get users => _users;
  DailySummary get summary => _summary;
  bool get isConfigExpanded => _isConfigExpanded;
  bool get showFixFields => _showFixFields;
  String get lotteryStatus => _lotteryStatus;
  String get lotteryErrorMsg => _lotteryErrorMsg;

  AppState() {
    _lotteryStatus = 'loading';
    _loadPersistedData();
  }

  /// 当前时间是否已过每日截单时间（21:35）
  static bool _isPastCutoff() {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, _cutoffHour, _cutoffMinute);
    return now.isAfter(cutoff);
  }

  /// 明天的日期字符串
  static String _nextDate(String date) {
    final dt = DateTime.parse(date);
    return _formatDate(dt.add(const Duration(days: 1)));
  }

  /// 保存当天快照到历史
  void _saveCurrentDay() {
    _savedDays[_currentDate] = _DaySnapshot(
      config: _config,
      users: List.from(_users),
      summary: _summary,
      userCounter: _userCounter,
    );
  }

  /// 加载历史日期的快照
  bool _loadDay(String date) {
    final snap = _savedDays[date];
    if (snap != null) {
      _config = snap.config;
      _users = List.from(snap.users);
      _summary = snap.summary;
      _userCounter = snap.userCounter;
      return true;
    }
    return false;
  }

  /// 如果已过截单时间且当前日期是今天，自动进入下一天
  bool _tryAdvanceDate() {
    final today = _formatDate(DateTime.now());
    if (_currentDate == today && _isPastCutoff()) {
      _saveCurrentDay();
      _currentDate = _nextDate(today);
      _config = DateConfig();
      _users = [];
      _userCounter = 0;
      _recalcSummary();
      return true;
    }
    return false;
  }

  /// 从 localStorage 加载所有持久化数据（同步，仅限 Web）
  void _loadPersistedData() {
    try {
      final storage = html.window.localStorage;

      // 检测 reset 标记，清理所有缓存（URL 加 #reset 即可）
      if (html.window.location.href.contains('reset')) {
        storage.clear();
        final clean = html.window.location.href.replaceAll('reset', '');
        html.window.location.href = clean;
        return;
      }

      final savedDate = storage['current_date'];
      if (savedDate != null && savedDate.isNotEmpty) {
        _currentDate = savedDate;
      }

      // 扫描所有 day_ 前缀的键加载历史数据
      for (final key in storage.keys) {
        if (key.startsWith('day_')) {
          final jsonStr = storage[key];
          if (jsonStr != null && jsonStr.isNotEmpty) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              final date = key.substring(4);
              _savedDays[date] = _DaySnapshot.fromJson(json);
            } catch (_) {
              debugPrint('[Persistence] 跳过损坏的数据: $key');
            }
          }
        }
      }

      // 加载当天数据
      if (_savedDays.containsKey(_currentDate)) {
        final snap = _savedDays[_currentDate]!;
        _config = snap.config;
        _users = List.from(snap.users);
        _summary = snap.summary;
        _userCounter = snap.userCounter;
        _lotteryStatus = _config.drawNo.isNotEmpty ? 'synced' : 'none';
      }

      debugPrint('[Persistence] 加载完成: $_currentDate, 共 ${_savedDays.length} 天');
    } catch (e) {
      debugPrint('[Persistence] 加载失败，使用默认值: $e');
    }

    _loaded = true;
    notifyListeners();
    // 加载完成后尝试获取最新数据
    _autoFetch();
  }

  /// 持久化当前状态到 localStorage
  void _persistAll() {
    if (!_loaded) return;

    try {
      _savedDays[_currentDate] = _DaySnapshot(
        config: _config,
        users: List.from(_users),
        summary: _summary,
        userCounter: _userCounter,
      );

      final storage = html.window.localStorage;
      storage['current_date'] = _currentDate;
      storage['day_$_currentDate'] =
          jsonEncode(_savedDays[_currentDate]!.toJson());
    } catch (e) {
      debugPrint('[Persistence] 保存失败: $e');
    }
  }

  Future<void> _autoFetch() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await fetchDrawData();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  void toggleConfig() {
    _isConfigExpanded = !_isConfigExpanded;
    notifyListeners();
  }

  void toggleFixFields() {
    _showFixFields = !_showFixFields;
    notifyListeners();
  }

  void switchDate(String date) {
    if (date == _currentDate) return;
    _saveCurrentDay();
    _currentDate = date;
    if (!_loadDay(date)) {
      _config = DateConfig();
      _users = [];
      _userCounter = 0;
      _recalcSummary();
    }
    _persistAll();
    notifyListeners();
  }

  void updateDrawNo(String no) {
    _config = _config.copyWith(drawNo: no);
    if (no.isEmpty) {
      _lotteryStatus = 'none';
    } else {
      _lotteryStatus = 'synced';
    }
    _recalcAll();
    _persistAll();
    notifyListeners();
  }

  void updateDrawNumbers(List<String> numbers) {
    _config = _config.copyWith(drawNumbers: numbers);
    _recalcAll();
    _persistAll();
    notifyListeners();
  }

  void updateDrawInfo(String info) {
    _config = _config.copyWith(drawInfo: info);
    _persistAll();
    notifyListeners();
  }

  /// 从网络获取实时开奖数据
  Future<void> fetchDrawData() async {
    _lotteryStatus = 'loading';
    _lotteryErrorMsg = '';
    notifyListeners();

    try {
      final data = await LotteryFetcher.fetchDrawData();
      if (data != null) {
        _config = _config.copyWith(
          drawInfo: data.drawInfo,
          drawNo: data.special,
          drawNumbers: data.numbers,
        );
        _lotteryStatus = 'synced';
      } else {
        _lotteryStatus = 'failed';
        _lotteryErrorMsg = '所有数据源均无法获取，请检查网络或稍后重试';
      }
    } catch (e) {
      _lotteryStatus = 'failed';
      _lotteryErrorMsg = '请求异常：$e';
    }

    _recalcAll();
    _persistAll();
    notifyListeners();
  }

  /// 保存配置（双向同步 rateConfig ↔ rateCode/rateZodiac）
  void updateConfig({
    int? rateCode,
    int? rateZodiac,
    RateConfig? rateConfig,
  }) {
    var newRateConfig = rateConfig ?? _config.rateConfig;

    if (rateConfig != null) {
      // 赔率编辑器 → 同步快捷字段
      rateCode ??= rateConfig.getOdds('特码').toInt();
      rateZodiac ??= rateConfig.getOdds('平肖').toInt();
    } else {
      // 快捷字段 → 同步赔率配置
      if (rateCode != null && rateCode != _config.rateCode) {
        newRateConfig = newRateConfig.withUpdatedOdds('特码', rateCode.toDouble());
      }
      if (rateZodiac != null && rateZodiac != _config.rateZodiac) {
        newRateConfig = newRateConfig.withUpdatedOdds('平肖', rateZodiac.toDouble());
      }
    }

    _config = _config.copyWith(
      rateCode: rateCode,
      rateZodiac: rateZodiac,
      rateConfig: newRateConfig,
    );
    _recalcAll();
    _persistAll();
    notifyListeners();
  }

  /// 简单添加用户（已过截单时间则自动进入下一天）
  void addUser() {
    _tryAdvanceDate();
    _userCounter++;
    _users.add(UserBet(id: 'A$_userCounter'));
    _recalcSummary();
    _persistAll();
    notifyListeners();
  }

  /// 带解析结果添加用户（已过截单时间则自动进入下一天）
  void addUserWithParsing(String rawInput, {String name = ''}) {
    final result = BetParser.parse(rawInput);
    if (result.hasError || result.isEmpty) return;

    _tryAdvanceDate();
    _userCounter++;
    final codeDisplay = result.codeAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');
    final zodiacDisplay = result.zodiacAmounts.entries
        .map((e) => '${e.key}(${e.value.toStringAsFixed(0)})')
        .join(', ');

    final user = UserBet(
      id: 'A$_userCounter',
      name: name,
      rawInput: rawInput,
      codeBets: codeDisplay,
      zodiacBets: zodiacDisplay,
      playBets: result.playDisplay,
      totalBet: result.totalAmount,
    );

    _users.add(user);
    _recalcUser(_users.length - 1);
    _recalcSummary();
    _persistAll();
    notifyListeners();
  }

  void removeUser(String id) {
    _users.removeWhere((u) => u.id == id);
    _recalcSummary();
    _persistAll();
    notifyListeners();
  }

  /// 清空所有日期的历史数据
  void clearAllHistory() {
    _config = DateConfig();
    _users = [];
    _userCounter = 0;
    _summary = DailySummary();
    _lotteryStatus = 'none';
    _savedDays.clear();
    try {
      final storage = html.window.localStorage;
      for (final key in storage.keys.toList()) {
        if (key.startsWith('day_')) storage.remove(key);
      }
      storage.remove('current_date');
    } catch (_) {}
    notifyListeners();
  }

  void clearToday() {
    _config = DateConfig();
    _users = [];
    _userCounter = 0;
    _summary = DailySummary();
    _lotteryStatus = 'none';
    _savedDays.remove(_currentDate);
    try {
      html.window.localStorage.remove('day_$_currentDate');
    } catch (_) {}
    notifyListeners();
  }

  void _recalcAll() {
    for (int i = 0; i < _users.length; i++) {
      _recalcUser(i);
    }
    _recalcSummary();
  }

  void _recalcUser(int idx) {
    final user = _users[idx];
    final drawNo = _config.drawNo;
    if (drawNo.isEmpty) {
      user.winCodeCount = 0;
      user.winZodiacCount = 0;
      user.playWinCount = 0;
      user.winMoney = 0;
      user.rebate = 0;
      return;
    }

    final target = drawNo.padLeft(2, '0');
    final dn = int.tryParse(drawNo) ?? 0;
    final codeMap = _parseAmountMap(user.codeBets);
    final zodiacMap = _parseAmountMap(user.zodiacBets);
    final playMap = _parseAmountMap(user.playBets);

    // 所有开奖号码
    final allNums = <int>{dn};
    for (final ns in _config.drawNumbers) {
      final n = int.tryParse(ns);
      if (n != null) allNums.add(n);
    }
    // 平码（不含特码）
    final flatNums = <int>{...allNums}..remove(dn);

    // ===== 特码 =====
    user.winCodeCount = codeMap.containsKey(target) ? 1 : 0;
    double money = 0;
    if (codeMap.containsKey(target)) {
      money += codeMap[target]! * _config.rateCode;
    }

    // ===== 生肖 =====
    user.winZodiacCount = 0;
    for (final num in allNums) {
      final z = ZodiacMap.getZodiac(num);
      if (z.isNotEmpty && zodiacMap.containsKey(z)) {
        user.winZodiacCount++;
        money += zodiacMap[z]! * _config.rateZodiac;
      }
    }

    // ===== 玩法算赢 =====
    final playWin = _calcPlayWin(playMap, dn, allNums, flatNums);
    user.playWinCount = playWin.$2;
    money += playWin.$1;
    user.winMoney = money;

    // ===== 返水 =====
    double rebate = 0;
    for (final e in codeMap.entries) {
      rebate += e.value * _config.rateConfig.getRebate('特码');
    }
    for (final e in zodiacMap.entries) {
      rebate += e.value * _config.rateConfig.getRebate('平肖');
    }
    for (final e in playMap.entries) {
      rebate += e.value * _config.rateConfig.getRebate(_playBaseName(e.key));
    }
    user.rebate = rebate;
  }

  /// 玩法算赢逻辑，返回 (赢钱总额, 中奖玩法数)
  (double, int) _calcPlayWin(Map<String, double> playMap, int dn,
      Set<int> allNums, Set<int> flatNums) {
    double win = 0;
    int winCount = 0;
    final dz = ZodiacMap.getZodiac(dn);
    final dTail = dn % 10;

    for (final entry in playMap.entries) {
      final key = entry.key;
      final amount = entry.value;
      double? won;

      // 1. 二友/三友/四友/五友（可选带马）— 所选生肖全部出现在开奖号码中
      var m = RegExp(
              r'^([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)(二友|三友|四友|五友)(带马)?$')
          .firstMatch(key);
      if (m != null) {
        final playType = m.group(2)!;
        final withHorse = m.group(3) != null;
        final allPresent = _allZodiacsInDrawn(m.group(1)!, allNums);
        final horseOk = !withHorse ||
            allNums.any((n) => ZodiacMap.getZodiac(n) == '马');
        if (allPresent && horseOk) {
          won = amount *
              _config.rateConfig.getOdds(
                  withHorse ? '${playType}带马' : playType);
        }
      }

      // 2. 特单/特双/单双/双单
      if (won == null) {
        if ((key == '特单' || key == '单双') && dn % 2 == 1) {
          won = amount * _config.rateConfig.getOdds('特单双');
        } else if ((key == '特双' || key == '双单') && dn % 2 == 0) {
          won = amount * _config.rateConfig.getOdds('特单双');
        }
      }

      // 3. 特大/特小
      if (won == null) {
        if (key == '特大' && dn > 24) {
          won = amount * _config.rateConfig.getOdds('特大小');
        } else if (key == '特小' && dn <= 24) {
          won = amount * _config.rateConfig.getOdds('特大小');
        }
      }

      // 4. 波色
      if (won == null) {
        final w = ZodiacMap.getWave(dn);
        if (key == '红波' && w == '红') {
          won = amount * _config.rateConfig.getOdds('红波');
        } else if (key == '蓝波' && w == '蓝') {
          won = amount * _config.rateConfig.getOdds('蓝波');
        } else if (key == '绿波' && w == '绿') {
          won = amount * _config.rateConfig.getOdds('绿波');
        } else if (key == '蓝绿波' && (w == '蓝' || w == '绿')) {
          won = amount * _config.rateConfig.getOdds('蓝波');
        }
      }

      // 5. 本肖马
      if (won == null && key == '本肖马' && dz == '马') {
        won = amount * _config.rateConfig.getOdds('本肖马');
      }

      // 6. 0尾
      if (won == null && key == '0尾' && dTail == 0) {
        won = amount * _config.rateConfig.getOdds('0尾');
      }

      // 7. 独平NN
      if (won == null) {
        m = RegExp(r'^独平(\d{2})$').firstMatch(key);
        if (m != null && flatNums.contains(int.parse(m.group(1)!))) {
          won = amount * _config.rateConfig.getOdds('独平');
        }
      }

      // 8. 尾数N
      if (won == null) {
        m = RegExp(r'^尾数(\d)$').firstMatch(key);
        if (m != null && dTail == int.parse(m.group(1)!)) {
          won = amount * _config.rateConfig.getOdds('尾数');
        }
      }

      // 9. 二中二/连特 A B
      if (won == null) {
        m = RegExp(r'^(二中二|连特)(\d{2})\s+(\d{2})$').firstMatch(key);
        if (m != null &&
            flatNums.contains(int.parse(m.group(2)!)) &&
            flatNums.contains(int.parse(m.group(3)!))) {
          won = amount * _config.rateConfig.getOdds(m.group(1)!);
        }
      }

      // 10. 五不中～十不中
      if (won == null) {
        m = RegExp(r'^((?:五|六|七|八|九|十)不中)((?:\d{2}\s+)*\d{2})$')
            .firstMatch(key);
        if (m != null) {
          final nums =
              m.group(2)!.split(RegExp(r'\s+')).map(int.parse).toSet();
          if (nums.every((n) => !allNums.contains(n))) {
            won = amount * _config.rateConfig.getOdds(m.group(1)!);
          }
        }
      }

      // 11. 六肖中特/五肖中特 + zodiacs
      if (won == null) {
        m = RegExp(r'^((?:六|五)肖中特)([鼠牛虎兔龙蛇马羊猴鸡狗猪]+)$')
            .firstMatch(key);
        if (m != null && m.group(2)!.contains(dz)) {
          won = amount * _config.rateConfig.getOdds(m.group(1)!);
        }
      }

      // 12. 二连尾/三连尾/四连尾 — 特码尾数在固定尾数区间内
      if (won == null) {
        const tailRanges = {
          '二连尾': {0, 1},
          '三连尾': {0, 1, 2},
          '四连尾': {0, 1, 2, 3},
        };
        final range = tailRanges[key];
        if (range != null && range.contains(dTail)) {
          won = amount * _config.rateConfig.getOdds(key);
        }
      }

      if (won != null && won > 0) {
        win += won;
        winCount++;
      }
    }

    return (win, winCount);
  }

  /// 检查全部生肖是否出现在开奖号码中
  bool _allZodiacsInDrawn(String zodiacs, Set<int> allNums) {
    for (int i = 0; i < zodiacs.length; i++) {
      if (!allNums.any((n) => ZodiacMap.getZodiac(n) == zodiacs[i])) {
        return false;
      }
    }
    return true;
  }

  /// 从玩法 key 中提取基础玩法名称（用于查赔率/返水）
  static String _playBaseName(String key) {
    // 友类带马: "鸡兔二友带马" → "二友带马"
    var m = RegExp(r'(二友带马|三友带马|四友带马|五友带马)$').firstMatch(key);
    if (m != null) return m.group(1)!;
    // 友类: "鸡兔二友" → "二友"
    m = RegExp(r'(二友|三友|四友|五友)$').firstMatch(key);
    if (m != null) return m.group(1)!;
    if (key.startsWith('独平')) return '独平';
    if (RegExp(r'^尾数\d$').hasMatch(key)) return '尾数';
    if (key.startsWith('二中二')) return '二中二';
    if (key.startsWith('连特')) return '连特';
    if (key.startsWith('六肖中特')) return '六肖中特';
    if (key.startsWith('五肖中特')) return '五肖中特';
    m = RegExp(r'^(五不中|六不中|七不中|八不中|九不中|十不中)')
        .firstMatch(key);
    if (m != null) return m.group(1)!;
    if (key == '单双' || key == '双单') return '特单双';
    if (key == '蓝绿波') return '蓝波';
    return key;
  }

  void _recalcSummary() {
    double totalBet = 0;
    double totalWin = 0;
    double totalRebate = 0;
    for (final u in _users) {
      totalBet += u.totalBet;
      totalWin += u.winMoney;
      totalRebate += u.rebate;
    }
    _summary = DailySummary(
      totalBet: totalBet,
      totalWin: totalWin,
      totalRebate: totalRebate,
      pay: totalWin - totalBet,
      userCount: _users.length,
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 解析 "08(750), 20(750)" → {"08": 750, "20": 750}
  static Map<String, double> _parseAmountMap(String raw) {
    final map = <String, double>{};
    for (final s in raw.split(',')) {
      final t = s.trim();
      if (t.isEmpty) continue;
      final p = t.split('(');
      if (p.length == 2) {
        final amt = double.tryParse(p[1].replaceAll(')', ''));
        if (amt != null) map[p[0].trim()] = amt;
      }
    }
    return map;
  }
}

/// 每日历史数据快照
class _DaySnapshot {
  final DateConfig config;
  final List<UserBet> users;
  final DailySummary summary;
  final int userCounter;

  _DaySnapshot({
    required this.config,
    required this.users,
    required this.summary,
    required this.userCounter,
  });

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'users': users.map((u) => u.toJson()).toList(),
        'summary': summary.toJson(),
        'userCounter': userCounter,
      };

  factory _DaySnapshot.fromJson(Map<String, dynamic> json) {
    return _DaySnapshot(
      config:
          DateConfig.fromJson(json['config'] as Map<String, dynamic>),
      users: (json['users'] as List)
          .map((u) => UserBet.fromJson(u as Map<String, dynamic>))
          .toList(),
      summary: DailySummary.fromJson(
          json['summary'] as Map<String, dynamic>),
      userCounter: json['userCounter'] as int,
    );
  }
}
