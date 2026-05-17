import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/app_state.dart';

class BottomSummaryBar extends StatelessWidget {
  const BottomSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final s = state.summary;
        return Container(
          height: AppTheme.bottomBarHeight,
          color: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              _SummaryItem(
                label: '总人数',
                value: '${s.userCount}',
              ),
              _SummaryItem(
                label: '总投注',
                value: '¥${s.totalBet.toStringAsFixed(0)}',
              ),
              _SummaryItem(
                label: '总中奖',
                value: '¥${s.totalWin.toStringAsFixed(0)}',
              ),
              _SummaryItem(
                label: '返水总额',
                value: '¥${s.totalRebate.toStringAsFixed(2)}',
              ),
              _SummaryItem(
                label: '实付',
                value: '¥${s.pay.toStringAsFixed(0)}',
                isHighlight: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xB3FFFFFF),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlight ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
