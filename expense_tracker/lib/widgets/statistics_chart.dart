import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart' show AppColors, formatAmount;

class StatisticsChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const StatisticsChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              '暂无$title数据',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final total = data.values.fold<double>(0, (a, b) => a + b);
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.lime,
      Colors.brown,
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildSections(colors, total),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildLegend(colors),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(List<Color> colors, double total) {
    int i = 0;
    return data.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final section = PieChartSectionData(
        value: entry.value,
        color: colors[i % colors.length],
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        radius: 60,
      );
      i++;
      return section;
    }).toList();
  }

  List<Widget> _buildLegend(List<Color> colors) {
    int i = 0;
    return data.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.key)),
            Text(
              formatAmount(entry.value),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }).toList();
  }
}
