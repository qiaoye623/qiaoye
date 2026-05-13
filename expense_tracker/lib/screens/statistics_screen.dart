import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/transaction_provider.dart';
import '../widgets/statistics_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<TransactionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: const Text('统计分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          provider.getCategorySummary('expense'),
          provider.getCategorySummary('income'),
        ]),
        builder: (context, AsyncSnapshot<List<Map<String, double>>> snapshot) {
          final expenseData = snapshot.hasData ? snapshot.data![0] : <String, double>{};
          final incomeData = snapshot.hasData ? snapshot.data![1] : <String, double>{};
          final totalExpense = expenseData.values.fold<double>(0, (a, b) => a + b);
          final totalIncome = incomeData.values.fold<double>(0, (a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildOverviewItem('总收入', totalIncome, const Color(0xFF52C41A))),
                    Container(width: 1, height: 30, color: const Color(0xFFEEEEEE)),
                    Expanded(child: _buildOverviewItem('总支出', totalExpense, const Color(0xFFF5222D))),
                    Container(width: 1, height: 30, color: const Color(0xFFEEEEEE)),
                    Expanded(child: _buildOverviewItem('结余', totalIncome - totalExpense, const Color(0xFF333333))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (expenseData.isNotEmpty) ...[
                const Text('支出分布',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: StatisticsChart(data: expenseData, title: ''),
                ),
                const SizedBox(height: 12),
                ...expenseData.entries.map((e) => _buildRankItem(e.key, e.value, totalExpense)),
              ],
              if (incomeData.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('收入分布',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: StatisticsChart(data: incomeData, title: ''),
                ),
                const SizedBox(height: 12),
                ...incomeData.entries.map((e) => _buildRankItem(e.key, e.value, totalIncome)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        const SizedBox(height: 4),
        Text(formatAmount(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRankItem(String name, double amount, double total) {
    final pct = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.circle, size: 8, color: Color(0xFF1677FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
          ),
          Text('$pct%',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          const SizedBox(width: 12),
          Text(formatAmount(amount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
        ],
      ),
    );
  }
}
