import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class AnnualBillScreen extends StatefulWidget {
  const AnnualBillScreen({super.key});

  @override
  State<AnnualBillScreen> createState() => _AnnualBillScreenState();
}

class _AnnualBillScreenState extends State<AnnualBillScreen> {
  final _db = DatabaseHelper();
  int _selectedYear = DateTime.now().year;
  bool _loading = true;

  final _monthlyData = <Map<String, double>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _monthlyData.clear();

    for (int month = 1; month <= 12; month++) {
      final summary = await _db.getMonthlySummary(_selectedYear, month);
      _monthlyData.add(summary);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _previousYear() {
    setState(() => _selectedYear--);
    _loadData();
  }

  void _nextYear() {
    setState(() => _selectedYear++);
    _loadData();
  }

  double get _totalIncome =>
      _monthlyData.fold<double>(0, (sum, m) => sum + (m['income'] ?? 0));
  double get _totalExpense =>
      _monthlyData.fold<double>(0, (sum, m) => sum + (m['expense'] ?? 0));
  double get _totalBalance => _totalIncome - _totalExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: const Text('年度账单',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildYearSelector(),
                  const SizedBox(height: 16),
                  _buildAnnualSummary(),
                  const SizedBox(height: 16),
                  _buildMonthlyChart(),
                  const SizedBox(height: 16),
                  _buildMonthlyList(),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24, color: Color(0xFF333333)),
            onPressed: _previousYear,
          ),
          const SizedBox(width: 16),
          Text(
            '$_selectedYear 年',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24, color: Color(0xFF333333)),
            onPressed: _nextYear,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1677FF), Color(0xFF4096FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('年度结余', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            formatAmount(_totalBalance),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总收入', _totalIncome, Colors.greenAccent),
              _buildStatItem('总支出', _totalExpense, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    final maxAmount = _monthlyData.fold<double>(0, (max, m) {
      final total = (m['income'] ?? 0) + (m['expense'] ?? 0);
      return total > max ? total : max;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('月度趋势',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final income = _monthlyData[index]['income'] ?? 0;
                final expense = _monthlyData[index]['expense'] ?? 0;
                final total = income + expense;
                final barHeight = maxAmount > 0 ? (total / maxAmount) * 120 : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1677FF), Color(0xFF4096FF)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1}月',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('月度明细',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          ),
          ...List.generate(12, (index) {
            final month = index + 1;
            final income = _monthlyData[index]['income'] ?? 0;
            final expense = _monthlyData[index]['expense'] ?? 0;
            final balance = income - expense;

            return Column(
              children: [
                if (index > 0) const Divider(height: 1, indent: 16, color: Color(0xFFEEEEEE)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text('$month月',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('收 ${formatAmount(income)}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF52C41A))),
                      ),
                      Expanded(
                        child: Text('支 ${formatAmount(expense)}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFFF5222D))),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          balance >= 0 ? '+${formatAmount(balance)}' : formatAmount(balance),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: balance >= 0 ? const Color(0xFF52C41A) : const Color(0xFFF5222D),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
