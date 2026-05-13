import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/ledger.dart';
import '../providers/transaction_provider.dart';
import '../providers/ledger_provider.dart';
import '../widgets/transaction_list_item.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class LedgerDetailScreen extends StatefulWidget {
  final Ledger ledger;
  const LedgerDetailScreen({super.key, required this.ledger});

  @override
  State<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends State<LedgerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<TransactionProvider>()
        .setCurrentLedgerId(widget.ledger.id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.ledger.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSummaryBar(provider),
              const SizedBox(height: 8),
              Expanded(
                child: provider.transactions.isEmpty
                    ? const Center(
                        child: Text('暂无记录',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        itemCount: provider.transactions.length,
                        itemBuilder: (context, index) {
                          final t = provider.transactions[index];
                          return TransactionListItem(
                            transaction: t,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditTransactionScreen(transaction: t),
                              ),
                            ),
                            onDelete: () => _confirmDeleteTxn(context, t.id!),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                      preSelectedLedgerId: widget.ledger.id),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar(TransactionProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.summaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildItem('支出', provider.monthlyExpense),
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(
            child: _buildItem('收入', provider.monthlyIncome),
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Text('结余',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  formatAmount(provider.balance),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, double amount) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账本'),
        content: Text('确定要删除"${widget.ledger.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context
                    .read<LedgerProvider>()
                    .deleteLedger(widget.ledger.id!);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTxn(BuildContext context, int id) {
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
              context.read<TransactionProvider>().deleteTransaction(id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
