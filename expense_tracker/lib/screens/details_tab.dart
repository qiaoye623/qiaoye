import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/asset_account_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/calendar_view.dart';
import 'asset_account_screen.dart';
import 'statistics_screen.dart';
import 'edit_transaction_screen.dart';

class DetailsTab extends StatefulWidget {
  const DetailsTab({super.key});

  @override
  State<DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: AppBar(
              title: _buildMonthSelector(provider),
              centerTitle: true,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryBar(provider),
              const SizedBox(height: 20),
              _buildGridMenu(context),
              const SizedBox(height: 20),
              _buildBillList(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(TransactionProvider provider) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime(provider.currentYear, provider.currentMonth);
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('zh', 'CN'),
        );
        if (picked != null && mounted) {
          provider.goToMonth(picked.year, picked.month);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => provider.goToPrevMonth(),
            child: const Icon(Icons.chevron_left, color: Color(0xFF333333)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${provider.currentYear}年${provider.currentMonth}月',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => provider.goToNextMonth(),
            child: const Icon(Icons.chevron_right, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(TransactionProvider provider) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCol('支出', provider.monthlyExpense)),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(child: _buildSummaryCol('收入', provider.monthlyIncome)),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(child: _buildSummaryCol('结余', provider.balance)),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(String label, double amount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    final items = [
      {'icon': Icons.pie_chart_outline, 'label': '统计分析', 'color': const Color(0xFF1677FF)},
      {'icon': Icons.calendar_month_outlined, 'label': '账单日历', 'color': const Color(0xFF52C41A)},
      {'icon': Icons.account_balance_wallet_outlined, 'label': '资产账户', 'color': const Color(0xFFFA8C16)},
      {'icon': Icons.search, 'label': '搜索', 'color': const Color(0xFF722ED1)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _onGridTap(context, item['label'] as String),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item['icon'] as IconData,
                        color: item['color'] as Color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(item['label'] as String,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onGridTap(BuildContext context, String label) {
    switch (label) {
      case '统计分析':
        _showStatisticsSheet(context);
        break;
      case '账单日历':
        _showCalendarPage(context);
        break;
      case '资产账户':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssetAccountScreen()),
        );
        break;
      case '搜索':
        _showSearch(context);
        break;
    }
  }

  void _showStatisticsSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
    );
  }

  void _showCalendarPage(BuildContext context) {
    final provider = context.read<TransactionProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CalendarPage(provider: provider),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _BillSearchDelegate(),
    );
  }

  Widget _buildBillList(BuildContext context, TransactionProvider provider) {
    if (provider.transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Color(0xFFEEEEEE)),
              SizedBox(height: 12),
              Text('暂无数据',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            ],
          ),
        ),
      );
    }

    // Group transactions by date
    final grouped = <String, List>{};
    for (final t in provider.transactions) {
      grouped.putIfAbsent(t.date, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDates.map((date) {
        final txns = grouped[date]!;
        final dayTotal = txns.fold<double>(0, (sum, t) => sum + t.amount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                  Text('支出: ${formatAmount(dayTotal)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            ...txns.map((t) => TransactionListItem(
                  transaction: t,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditTransactionScreen(transaction: t),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, t),
                )),
          ],
        );
      }).toList(),
    );
  }

  void _confirmDelete(BuildContext context, Transaction txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TransactionProvider>().deleteTransaction(txn.id!);
              if (txn.accountId != null) {
                final accountProvider = context.read<AssetAccountProvider>();
                final delta = txn.type == 'income' ? -txn.amount : txn.amount;
                final account = accountProvider.accounts.firstWhere((a) => a.id == txn.accountId);
                accountProvider.updateBalance(txn.accountId!, account.balance + delta);
              }
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Calendar page
class _CalendarPage extends StatefulWidget {
  final TransactionProvider provider;
  const _CalendarPage({required this.provider});

  @override
  State<_CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<_CalendarPage> {
  late int _year;
  late int _month;
  Map<String, double> _dailyData = {};

  @override
  void initState() {
    super.initState();
    _year = widget.provider.currentYear;
    _month = widget.provider.currentMonth;
    _loadData();
  }

  void _loadData() async {
    final data = await widget.provider.getDailySummariesForMonth();
    if (mounted) setState(() => _dailyData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  if (_month == 1) { _year--; _month = 12; } else { _month--; }
                });
                _loadData();
              },
            ),
            Text('$_year年$_month月'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  if (_month == 12) { _year++; _month = 1; } else { _month++; }
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CalendarView(
              year: _year,
              month: _month,
              dailyData: _dailyData,
              onDaySelected: (dateStr) {
                final dayTxns = widget.provider.transactions
                    .where((t) => t.date == dateStr)
                    .toList();
                if (dayTxns.isEmpty) return;
                showModalBottomSheet(
                  context: context,
                  builder: (_) => _buildDayDetail(dateStr, dayTxns),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail(String dateStr, List transactions) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...transactions.map((t) => TransactionListItem(transaction: t)),
        ],
      ),
    );
  }
}

// Search delegate
class _BillSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => '搜索账单';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final results = provider.transactions
        .where((t) =>
            t.categoryName.contains(query) ||
            t.note.contains(query) ||
            t.date.contains(query))
        .toList();
    return ListView(
      children: results
          .map((t) => TransactionListItem(transaction: t))
          .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
