import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/app_state.dart';

class TopNavBar extends StatefulWidget {
  const TopNavBar({super.key});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  String _timeStr = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final str = '$y-$m-$d $h:$min:$s';
    if (str != _timeStr) {
      setState(() => _timeStr = str);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Container(
          height: AppTheme.navBarHeight,
          color: AppTheme.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // 实时时间
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日期选择弹窗')),
                ),
                child: SizedBox(
                  width: 108,
                  child: Text(
                    _timeStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              // 标题
              const Expanded(
                child: Center(
                  child: Text(
                    '投注计算器',
                    style: TextStyle(
                      fontSize: AppTheme.titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              // 图标区
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopIcon(
                    icon: Icons.sync,
                    tooltip: '实时特码',
                    badge: state.lotteryStatus,
                    onTap: () async {
                      await context.read<AppState>().fetchDrawData();
                      final s = context.read<AppState>();
                      if (s.lotteryStatus == 'failed') {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.lotteryErrorMsg.isNotEmpty
                                  ? s.lotteryErrorMsg
                                  : '获取失败'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 15),
                  _TopIcon(
                    icon: Icons.pets,
                    tooltip: '生肖对照',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('生肖对照弹窗')),
                    ),
                  ),
                  const SizedBox(width: 15),
                  _TopIcon(
                    icon: Icons.build,
                    tooltip: '修正模式',
                    onTap: () => context.read<AppState>().toggleFixFields(),
                  ),
                  const SizedBox(width: 15),
                  _TopIcon(
                    icon: Icons.calendar_today,
                    tooltip: '日历查看',
                    onTap: () => _showCalendarDialog(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? badge;
  final VoidCallback onTap;

  const _TopIcon({
    required this.icon,
    required this.tooltip,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24, color: AppTheme.textPrimary),
          if (badge != null && badge!.isNotEmpty && badge != 'none')
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badge == 'synced'
                      ? AppTheme.success
                      : badge == 'loading'
                          ? AppTheme.primary
                          : AppTheme.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge == 'synced'
                      ? '已同步'
                      : badge == 'loading'
                          ? '加载中'
                          : '获取失败',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showCalendarDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) {
      DateTime selected = DateTime.now();
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('选择日期查看记录'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selected,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => selected = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final date =
                      '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                  Navigator.pop(ctx);
                  context.read<AppState>().switchDate(date);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.white,
                ),
                child: const Text('确认查看'),
              ),
            ],
          );
        },
      );
    },
  );
}
