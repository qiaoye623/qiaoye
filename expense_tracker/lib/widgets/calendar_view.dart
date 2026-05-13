import 'package:flutter/material.dart';
import '../utils/constants.dart' show AppColors;

class CalendarView extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, double> dailyData;
  final ValueChanged<String>? onDaySelected;

  const CalendarView({
    super.key,
    required this.year,
    required this.month,
    required this.dailyData,
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7;

    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Column(
      children: [
        Row(
          children: weekdays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox();
            final day = index - firstWeekday + 1;
            final dateStr =
                '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final hasData = dailyData.containsKey(dateStr);
            final isToday = dateStr ==
                DateTime.now().toIso8601String().substring(0, 10);

            return GestureDetector(
              onTap: hasData ? () => onDaySelected?.call(dateStr) : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : null,
                        color: isToday ? AppColors.primary : null,
                      ),
                    ),
                    if (hasData)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
