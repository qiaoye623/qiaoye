import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart' as cat;
import '../models/asset_account.dart';
import '../providers/transaction_provider.dart';
import '../providers/asset_account_provider.dart';
import '../utils/constants.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;
  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late String _selectedType;
  cat.Category? _selectedCategory;
  AssetAccount? _selectedAccount;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  final _noteFocusNode = FocusNode();
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _selectedType = t.type;
    _amountController = TextEditingController(text: t.amount.toString());
    _noteController = TextEditingController(text: t.note);
    _selectedDate = DateFormat('yyyy-MM-dd').parse(t.date);
    _selectedCategory = cat.Category(
      id: t.categoryId,
      name: t.categoryName,
      icon: t.categoryIcon,
      type: t.type,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: AppBar(
            title: const Text('编辑账单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              onPressed: _confirmBack,
            ),
            actions: [
              TextButton(
                onPressed: _saving || _amountController.text.trim().isEmpty ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 16,
                          color: _amountController.text.trim().isEmpty ? const Color(0xFF999999) : const Color(0xFF1677FF),
                        ),
                      ),
              ),
            ],
          ),
        ),
        body: ListView(
          children: [
            _buildTypeSelector(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildAmountInput(),
            Container(height: 1, color: const Color(0xFFEEEEEE)),
            _buildOptionList(),
          ],
        ),
      ),
    );
  }

  void _confirmBack() {
    final changed = _amountController.text.trim() != widget.transaction.amount.toString() ||
        _noteController.text.trim() != widget.transaction.note ||
        _selectedDate != DateFormat('yyyy-MM-dd').parse(widget.transaction.date) ||
        _selectedCategory?.id != widget.transaction.categoryId;
    if (changed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('提示'),
          content: const Text('是否放弃编辑？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              child: const Text('放弃', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 44,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildTab('支出', 'expense')),
          Expanded(child: _buildTab('收入', 'income')),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedCategory = null;
      }),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF1677FF) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? const Color(0xFF1677FF) : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      height: 120,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '请输入金额',
            hintStyle: TextStyle(fontSize: 16, color: Color(0xFF999999)),
          ),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _selectedType == 'expense' ? const Color(0xFFF5222D) : const Color(0xFF52C41A),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildOptionList() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      child: Column(
        children: [
          _buildOptionItem(
            Icons.category_outlined,
            '分类',
            _selectedCategory != null ? '${_selectedCategory!.icon} ${_selectedCategory!.name}' : '请选择',
            () => _showCategoryPicker(),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
          _buildOptionItem(
            Icons.account_balance_wallet_outlined,
            '账户',
            _selectedAccount != null ? '${_selectedAccount!.icon} ${_selectedAccount!.name}' : '请选择',
            () => _showAccountPicker(),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
          _buildDateItem(),
          const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
          _buildNoteItem(),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF333333)),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateItem() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 22, color: Color(0xFF333333)),
            const SizedBox(width: 16),
            const Text('日期', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
            const Spacer(),
            Text(DateFormat('yyyy-MM-dd').format(_selectedDate),
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.notes_outlined, size: 22, color: Color(0xFF333333)),
          const SizedBox(width: 16),
          const Text('备注', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '可选',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              maxLength: 50,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter: (context, {required currentLength, required maxLength, required isFocused}) => null,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    final provider = context.read<TransactionProvider>();
    final categories = _selectedType == 'expense'
        ? provider.expenseCategories
        : provider.incomeCategories;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final c = categories[index];
                final sel = _selectedCategory?.id == c.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = c);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1677FF).withOpacity(0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: sel ? Border.all(color: const Color(0xFF1677FF), width: 2) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(c.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                              color: sel ? const Color(0xFF1677FF) : const Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker() {
    final accounts = context.read<AssetAccountProvider>().accounts;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择账户', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...accounts.map((a) => ListTile(
                  leading: Text(a.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(a.name),
                  trailing: Text(formatAmount(a.balance),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    setState(() => _selectedAccount = a);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      _showError('请输入金额');
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _showError('请输入有效金额');
      return;
    }
    if (_selectedCategory == null) {
      _showError('请选择分类');
      return;
    }

    setState(() => _saving = true);

    final updated = Transaction(
      id: widget.transaction.id,
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategory!.id!,
      categoryName: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.icon,
      note: _noteController.text.trim(),
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      createdAt: widget.transaction.createdAt,
      ledgerId: widget.transaction.ledgerId,
    );

    await context.read<TransactionProvider>().updateTransaction(updated);
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
