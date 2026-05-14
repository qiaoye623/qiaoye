import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/constants.dart';
import '../providers/ledger_provider.dart';
import 'ledger_detail_screen.dart';

class LedgerTab extends StatelessWidget {
  const LedgerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: const Text('账本管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 22),
              onPressed: () {},
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: Consumer<LedgerProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...provider.ledgers.map((ledger) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildLedgerCard(context, ledger, provider),
                        )),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _showCreateDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52C41A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 24, color: Colors.white),
                            SizedBox(width: 4),
                            Text('新增账本', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '账本是用来分类管理你的账单，你可以创建多个账本（如：家庭账本、旅行账本）',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLedgerCard(BuildContext context, ledger, LedgerProvider provider) {
    final isDefault = ledger.isDefault ?? false;
    final income = provider.getLedgerIncome(ledger.id!);
    final expense = provider.getLedgerExpense(ledger.id!);
    final balance = provider.getLedgerBalance(ledger.id!);

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEditDialog(context, ledger),
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          if (!isDefault)
            SlidableAction(
              onPressed: (_) => provider.setDefaultLedger(ledger.id!),
              backgroundColor: const Color(0xFF52C41A),
              foregroundColor: Colors.white,
              icon: Icons.check_circle_outline,
              label: '默认',
            ),
          if (!isDefault)
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, ledger, provider),
              backgroundColor: const Color(0xFFF5222D),
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: '删除',
            ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          provider.switchLedger(ledger.id!);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LedgerDetailScreen(ledger: ledger),
            ),
          );
        },
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isDefault ? '📒' : ledger.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    ledger.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1677FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('默认',
                          style: TextStyle(fontSize: 10, color: Color(0xFF1677FF))),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                '支:${formatAmount(expense)} 收:${formatAmount(income)} 结:${formatAmount(balance)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ledger, LedgerProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账本'),
        content: Text('确定要删除"${ledger.name}"吗？将同时删除该账本下的所有账单。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteLedger(ledger.id!);
                if (ctx.mounted) Navigator.pop(ctx);
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

  void _showEditDialog(BuildContext context, ledger) {
    final nameController = TextEditingController(text: ledger.name);
    String selectedIcon = ledger.icon;
    final icons = [
      '📒', '💰', '🏠', '🚗', '🎮', '📚', '💼', '🎯', '✈️', '🍽️',
      '🏖️', '🎓', '🏥', '🐱', '🌸', '⭐'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑账本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '账本名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) {
                  final isSel = icon == selectedIcon;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF1677FF).withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: isSel ? Border.all(color: const Color(0xFF1677FF)) : null,
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await context
                    .read<LedgerProvider>()
                    .updateLedger(ledger.id!, nameController.text.trim(), selectedIcon);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存', style: TextStyle(color: Color(0xFF1677FF))),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedIcon = '📒';
    final icons = [
      '📒', '💰', '🏠', '🚗', '🎮', '📚', '💼', '🎯', '✈️', '🍽️',
      '🏖️', '🎓', '🏥', '🐱', '🌸', '⭐'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建账本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '账本名称',
                  hintText: '请输入账本名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('选择图标', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) {
                  final isSel = icon == selectedIcon;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF1677FF).withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: isSel ? Border.all(color: const Color(0xFF1677FF)) : null,
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await context
                      .read<LedgerProvider>()
                      .createLedger(nameController.text.trim(), selectedIcon);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('创建', style: TextStyle(color: Color(0xFF1677FF))),
            ),
          ],
        ),
      ),
    );
  }
}
