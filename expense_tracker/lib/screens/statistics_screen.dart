import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/statistics_chart.dart';
import '../widgets/summary_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${provider.currentYear}年${provider.currentMonth}月统计',
          style: const TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.goToPrevMonth(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.goToNextMonth(),
          ),
        ],
      ),
      body: provider.transactions.isEmpty
          ? const Center(
              child: Text(
                '本月暂无数据\n添加一些记录来查看统计',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : FutureBuilder(
              future: Future.wait([
                provider.getCategorySummary('expense'),
                provider.getCategorySummary('income'),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data!;
                Map<String, double> expenseData = results[0];
                Map<String, double> incomeData = results[1];

                return ListView(
                  children: [
                    SummaryCard(
                      income: provider.monthlyIncome,
                      expense: provider.monthlyExpense,
                      balance: provider.balance,
                    ),
                    StatisticsChart(
                      data: expenseData,
                      title: '支出分布',
                    ),
                    if (incomeData.isNotEmpty)
                      StatisticsChart(
                        data: incomeData,
                        title: '收入分布',
                      ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }
}
