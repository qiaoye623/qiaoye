import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/asset_account.dart';
import '../providers/asset_account_provider.dart';

class AssetAccountScreen extends StatelessWidget {
  const AssetAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: const Text('资产账户', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Consumer<AssetAccountProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final totalAssets = provider.accounts.fold<double>(
            0, (sum, a) => sum + a.balance);
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1677FF), Color(0xFF4096FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('总净资产',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(formatAmount(totalAssets),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...provider.accounts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAccountCard(context, a, provider),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _showAddDialog(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
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
                        Text('新增账户', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext context, AssetAccount account, AssetAccountProvider provider) {
    final typeLabel = _typeLabel(account.type);
    return GestureDetector(
      onTap: () => _showEditBalanceDialog(context, provider, account),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(account.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(account.name,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  const SizedBox(height: 2),
                  Text(typeLabel,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            Text(formatAmount(account.balance),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'wallet':
        return '钱包';
      case 'bank':
        return '银行卡';
      case 'credit':
        return '信用账户';
      case 'cash':
        return '现金';
      default:
        return type;
    }
  }

  void _showEditBalanceDialog(
      BuildContext context, AssetAccountProvider provider, AssetAccount account) {
    final controller = TextEditingController(text: account.balance.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${account.icon} ${account.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '金额',
            prefixText: '¥ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (!account.isDefault)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDelete(context, provider, account);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                provider.updateBalance(account.id!, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存', style: TextStyle(color: Color(0xFF1677FF))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AssetAccountProvider provider, AssetAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${account.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAccount(account.id!);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, AssetAccountProvider provider) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedIcon = '💳';
    String selectedType = 'wallet';
    final icons = ['💳', '📱', '💵', '🏦', '🌸', '🐶', '💰', '🏪'];
    final types = [
      {'key': 'wallet', 'label': '钱包'},
      {'key': 'bank', 'label': '银行卡'},
      {'key': 'credit', 'label': '信用账户'},
      {'key': 'cash', 'label': '现金'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新增账户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '账户名称',
                    hintText: '例如：招商银行',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '余额',
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('选择图标', style: TextStyle(fontSize: 13)),
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
                const SizedBox(height: 12),
                const Text('账户类型', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((t) {
                    final isSel = t['key'] == selectedType;
                    return ChoiceChip(
                      label: Text(t['label']!),
                      selected: isSel,
                      onSelected: (_) => setDialogState(() => selectedType = t['key']!),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0;
                if (name.isEmpty) return;
                try {
                  await provider.addAccount(name, selectedIcon, selectedType, balance);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('添加', style: TextStyle(color: Color(0xFF1677FF))),
            ),
          ],
        ),
      ),
    );
  }
}
