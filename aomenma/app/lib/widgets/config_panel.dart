import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/zodiac_map.dart';
import '../providers/app_state.dart';
import '../models/date_config.dart';
import '../models/rate_config.dart';
import '../models/draw_ball.dart';
import '../services/draw_parser.dart';

class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  late TextEditingController _drawNoCtrl;
  late List<TextEditingController> _drawNumCtrls;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<AppState>().config;
    _initControllers(cfg);
  }

  void _initControllers(DateConfig cfg) {
    _drawNoCtrl = TextEditingController(text: cfg.drawNo);
    _drawNumCtrls = List.generate(6, (i) => TextEditingController(
      text: i < cfg.drawNumbers.length ? cfg.drawNumbers[i] : '',
    ));
  }

  @override
  void dispose() {
    _drawNoCtrl.dispose();
    for (final c in _drawNumCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cfg = state.config;

    if (_drawNoCtrl.text != cfg.drawNo) {
      _drawNoCtrl.text = cfg.drawNo;
    }
    for (int i = 0; i < 6; i++) {
      final val = i < cfg.drawNumbers.length ? cfg.drawNumbers[i] : '';
      if (_drawNumCtrls[i].text != val) {
        _drawNumCtrls[i].text = val;
      }
    }
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppTheme.padding),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => state.toggleConfig(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '当期配置（${state.currentDate}）',
                    style: const TextStyle(
                      fontSize: AppTheme.bodySize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  state.isConfigExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          if (state.isConfigExpanded) ...[
            const SizedBox(height: AppTheme.padding),
            // 开奖信息（只读）
            if (cfg.drawInfo.isNotEmpty) ...[
              _DrawInfoBalls(drawInfo: cfg.drawInfo),
              // 修正功能区：默认隐藏，通过顶部按钮切换
              if (state.showFixFields) ...[
                const SizedBox(height: 8),
                _buildField('特码修正', _drawNoCtrl, '手动输入特码覆盖（1-49）',
                    onChanged: (v) => state.updateDrawNo(v)),
                const SizedBox(height: 4),
                _NumbersFixRow(ctrls: _drawNumCtrls, state: state),
              ],
              const Divider(height: 16),
            ] else ...[
              _buildField('特码', _drawNoCtrl, '输入特码（1-49），或点击顶部获取实时特码',
                  onChanged: (v) => state.updateDrawNo(v)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: AppTheme.margin),
            // 赔率设置按钮
            SizedBox(
              width: double.infinity,
              height: AppTheme.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () => _showRateEditor(context),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('赔率设置',
                    style: TextStyle(fontSize: AppTheme.bodySize)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRateEditor(BuildContext outerContext) {
    // 在外层捕获引用，避免对话框 context 遮盖问题
    final state = outerContext.read<AppState>();
    final messenger = ScaffoldMessenger.of(outerContext);
    // 克隆当前赔率配置供编辑
    final edited = <String, RateItem>{};
    for (final entry in state.config.rateConfig.items.entries) {
      edited[entry.key] = RateItem(
        odds: entry.value.odds,
        rebate: entry.value.rebate,
        type: entry.value.type,
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('赔率设置'),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '编辑各玩法赔率，修改后点击保存生效',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ...RateConfig.playNames.map((name) {
                        final item = edited[name]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 72,
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary)),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: item.odds.toStringAsFixed(
                                        item.odds == item.odds.roundToDouble()
                                            ? 0
                                            : 1),
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: '赔率',
                                    labelStyle: TextStyle(fontSize: 11),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null && val > 0) {
                                      setDialogState(() {
                                        edited[name] = RateItem(
                                          odds: val,
                                          rebate: item.rebate,
                                          type: item.type,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: (item.rebate * 100).toStringAsFixed(0),
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: '返水%',
                                    labelStyle: TextStyle(fontSize: 11),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null && val >= 0) {
                                      setDialogState(() {
                                        edited[name] = RateItem(
                                          odds: item.odds,
                                          rebate: val / 100,
                                          type: item.type,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    state.updateConfig(
                      rateConfig: RateConfig(items: edited),
                    );
                    Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('赔率已保存'),
                          duration: Duration(seconds: 2)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.white,
                  ),
                  child: const Text('保存赔率'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {bool readOnly = false, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(
                    fontSize: AppTheme.helperSize,
                    color: AppTheme.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              readOnly: readOnly,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    const TextStyle(fontSize: 12, color: AppTheme.textGray),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                filled: readOnly,
                fillColor: readOnly ? const Color(0xFFF9FAFB) : null,
              ),
              style: const TextStyle(fontSize: AppTheme.helperSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawInfoBalls extends StatelessWidget {
  final String drawInfo;
  const _DrawInfoBalls({required this.drawInfo});

  static const Color _redColor = Color(0xFFE53935);
  static const Color _blueColor = Color(0xFF3484E6);
  static const Color _greenColor = Color(0xFF2ABF50);
  static const Color _specialBorder = Color(0xFFFB8500);

  /// 根据号码的波色返回对应颜色，而非依赖 API 返回的元素字符串
  static Color _colorForNumber(String numStr) {
    final n = int.tryParse(numStr);
    if (n == null) return const Color(0xFF999999);
    final wave = ZodiacMap.getWave(n);
    switch (wave) {
      case '红': return _redColor;
      case '蓝': return _blueColor;
      case '绿': return _greenColor;
      default: return const Color(0xFF999999);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = DrawParser.parse(drawInfo);
    if (result.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(drawInfo,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textPrimary)),
      );
    }

    DrawBall? specialBall;
    final regularBalls = <DrawBall>[];
    for (final b in result.balls) {
      if (b.isSpecial) {
        specialBall = b;
      } else {
        regularBalls.add(b);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.period,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...regularBalls.map((ball) {
                return _BallCard(
                  ball: ball,
                  color: _colorForNumber(ball.number),
                );
              }),
              if (specialBall != null) ...[
                const SizedBox(width: 10),
                // 竖排"特码"标签
                Column(
                  children: '特码'
                      .split('')
                      .map((c) => Text(c,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                              height: 1.3)))
                      .toList(),
                ),
                const SizedBox(width: 6),
                _BallCard(
                  ball: specialBall,
                  color: _colorForNumber(specialBall.number),
                  borderColor: _specialBorder,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 6个平肖手动修正输入行
class _NumbersFixRow extends StatelessWidget {
  final List<TextEditingController> ctrls;
  final AppState state;
  const _NumbersFixRow({required this.ctrls, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('平肖修正',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: List.generate(6, (i) {
              final numStr = i < state.config.drawNumbers.length
                  ? state.config.drawNumbers[i]
                  : ctrls[i].text;
              final n = int.tryParse(numStr);
              Color bgColor;
              if (n != null && n >= 1 && n <= 49) {
                final wave = ZodiacMap.getWave(n);
                switch (wave) {
                  case '红': bgColor = const Color(0x20E63946); break;
                  case '蓝': bgColor = const Color(0x20457B9D); break;
                  case '绿': bgColor = const Color(0x202A9D8F); break;
                  default: bgColor = Colors.transparent;
                }
              } else {
                bgColor = Colors.transparent;
              }
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: TextField(
                    controller: ctrls[i],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '${i + 1}',
                      isDense: true,
                      filled: true,
                      fillColor: bgColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                        borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB)),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      final nums = ctrls.map((c) {
                        final t = c.text.trim();
                        return t.isEmpty ? '' : t.padLeft(2, '0');
                      }).toList();
                      state.updateDrawNumbers(nums);
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BallCard extends StatelessWidget {
  final DrawBall ball;
  final Color color;
  final Color? borderColor;

  const _BallCard({
    required this.ball,
    required this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ball.number,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ball.element}/${ball.zodiac}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
