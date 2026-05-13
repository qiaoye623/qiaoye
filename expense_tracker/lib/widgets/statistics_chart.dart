import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold<double>(0, (a, b) => a + b);
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(data: data, total: total, colors: colors),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.entries.take(6).map((e) {
                        final idx = data.keys.toList().indexOf(e.key);
                        final pct = (e.value / total * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[idx % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('${e.key} $pct%',
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PieChart extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final List<Color> colors;

  const PieChart({
    super.key,
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 140),
      painter: _PieChartPainter(data: data, total: total, colors: colors),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;
  final List<Color> colors;

  _PieChartPainter({
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var startAngle = -1.57;
    final entries = data.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 6.2832;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(rect.center, 30, centerPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: (total).toStringAsFixed(0),
        style: const TextStyle(
            color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => true;
}
