import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/app_state.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.margin),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _confirmClearToday(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.textGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: const Text('清空当日数据',
                        style: TextStyle(fontSize: AppTheme.helperSize)),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.margin),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _confirmClearAll(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: const Text('清空全部历史',
                        style: TextStyle(fontSize: AppTheme.helperSize)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearToday(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: Consumer<AppState>(
          builder: (_, state, __) => Text(
            '确定清空当前日期（${state.currentDate}）所有数据？',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<AppState>().clearToday();
              Navigator.pop(ctx);
            },
            child: const Text('确认', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定清空所有日期的历史数据？此操作不可恢复！'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<AppState>().clearAllHistory();
              Navigator.pop(ctx);
            },
            child: const Text('确认', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
