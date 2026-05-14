import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/save_provider.dart';
import '../../models/save_plan.dart';
import '../../models/save_record.dart';
import 'save_detail_screen.dart';

class SaveCreatePopup extends StatefulWidget {
  final String type;
  final SavePlan? editPlan;

  const SaveCreatePopup(
      {super.key, required this.type, this.editPlan});

  @override
  State<SaveCreatePopup> createState() => _SaveCreatePopupState();
}

class _SaveCreatePopupState extends State<SaveCreatePopup> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _monthAmountController = TextEditingController();
  final _daysController = TextEditingController();
  final _coeffController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _selectedIcon = 0;

  bool get isEdit => widget.editPlan != null;

  String get _typeName {
    switch (widget.type) {
      case '365':
        return '365天存钱';
      case '52week':
        return '52周存钱';
      case '12deposit':
        return '12存单';
      case 'elastic':
        return '弹性存钱';
      case 'flexible':
        return '灵活存钱';
      default:
        return '存钱';
    }
  }

  final List<int> _iconOptions = [0x1F4B0, 0x1F4B5, 0x1FA99, 0x1F4B8, 0x1F340, 0x2B50, 0x1F31F, 0x1F389];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final p = widget.editPlan!;
      _nameController.text = p.name;
      _amountController.text = p.startAmount.toStringAsFixed(0);
      _monthAmountController.text = p.monthAmount.toStringAsFixed(0);
      if (p.incrementCoeff > 0) {
        _coeffController.text = p.incrementCoeff.toStringAsFixed(0);
      }
      if (p.durationDays > 0) {
        _daysController.text = p.durationDays.toString();
      }
      _selectedIcon = p.iconCode;
    } else {
      switch (widget.type) {
        case '365':
          _amountController.text = '1';
          break;
        case '52week':
          _amountController.text = '10';
          break;
        case '12deposit':
          _monthAmountController.text = '100';
          break;
        case 'elastic':
          _amountController.text = '10';
          _daysController.text = '30';
          _coeffController.text = '2';
          break;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _monthAmountController.dispose();
    _daysController.dispose();
    _coeffController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? get _endDate {
    final days = _getDuration();
    if (days <= 0) return null;
    return DateTime(_startDate.year, _startDate.month, _startDate.day)
        .add(Duration(days: days - 1));
  }

  int _getDuration() {
    if (widget.type == 'flexible') return 0;
    final customDays = int.tryParse(_daysController.text);
    return SaveProvider.calcDuration(widget.type, customDays);
  }

  double _calcTotal() {
    if (widget.type == 'flexible') return 0;
    final startAmount = double.tryParse(_amountController.text) ?? 0;
    final monthAmount = double.tryParse(_monthAmountController.text) ?? 0;
    final days = _getDuration();
    final coeff = double.tryParse(_coeffController.text) ?? 0;
    return SaveProvider.calcTotalTarget(widget.type, startAmount, days, coeff, monthAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? '编辑$_typeName计划' : '创建$_typeName计划',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: Color(0xFF999999), size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _typeColor.withOpacity(0.1),
                      child: Text(
                        String.fromCharCode(_selectedIcon > 0 ? _selectedIcon : 0x1F4B0),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showIconPicker,
                      child: const Text('点击选择配图',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF999999))),
                    ),
                    const Spacer(),
                    Text(
                      _calcSummary(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('存钱计划名称', _nameController, '请输入计划名称'),
                const SizedBox(height: 12),
                _buildDateField('起始日期', _startDate, () => _pickDate(true)),
                const SizedBox(height: 12),
                _buildDateField('结束日期', _endDate, null, readOnly: true),
                const SizedBox(height: 12),
                if (widget.type == '12deposit') ...[
                  _buildField('每月存入金额（元）', _monthAmountController, '请输入每月金额',
                      keyboardType: TextInputType.number),
                ] else if (widget.type != 'flexible') ...[
                  _buildField('起始金额（元）', _amountController, '请输入起始金额',
                      keyboardType: TextInputType.number),
                ],
                if (widget.type == 'elastic') ...[
                  const SizedBox(height: 12),
                  _buildField('持续天数', _daysController, '请输入天数',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildField('递增系数（每日增加金额）', _coeffController, '请输入递增金额',
                      keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF52C41A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: Text(isEdit ? '保存' : '提交'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (widget.type) {
      case '365':
        return const Color(0xFF1677FF);
      case '52week':
        return const Color(0xFF52C41A);
      case '12deposit':
        return const Color(0xFFFA8C16);
      case 'elastic':
        return const Color(0xFF722ED1);
      case 'flexible':
        return const Color(0xFF999999);
      default:
        return const Color(0xFF52C41A);
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
      ),
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback? onTap,
      {bool readOnly = false}) {
    final dateStr = date != null ? _formatDate(date) : '--';
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF0F0F0) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF666666))),
          const Spacer(),
          GestureDetector(
            onTap: readOnly ? null : onTap,
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 14,
                color: readOnly
                    ? const Color(0xFF999999)
                    : const Color(0xFF333333),
              ),
            ),
          ),
          if (!readOnly) ...[
            const SizedBox(width: 4),
            const Icon(Icons.calendar_today,
                size: 16, color: Color(0xFF999999)),
          ],
        ],
      ),
    );
  }

  String _calcSummary() {
    final total = _calcTotal();
    if (total > 0) {
      final days = _getDuration();
      final unit = widget.type == '12deposit' ? '个月' : '天';
      return '$days$unit后可存 ¥${total.toStringAsFixed(2)}';
    }
    return '填写参数查看存钱目标';
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择配图'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _iconOptions.map((code) {
            final selected = _selectedIcon == code;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedIcon = code);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? _typeColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: selected
                      ? Border.all(color: _typeColor, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(String.fromCharCode(code),
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入计划名称')),
      );
      return;
    }

    final startAmount = double.tryParse(_amountController.text) ?? 0;
    final monthAmount = double.tryParse(_monthAmountController.text) ?? 0;
    final durationDays = _getDuration();
    final coeff = double.tryParse(_coeffController.text) ?? 0;

    if (widget.type == '12deposit') {
      if (monthAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效每月金额')),
        );
        return;
      }
    } else if (widget.type != 'flexible' && startAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效起始金额')),
      );
      return;
    }

    if (widget.type == 'elastic' && durationDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效持续天数')),
      );
      return;
    }

    final totalTarget = _calcTotal();
    final startDateStr = _formatDate(_startDate);

    final plan = SavePlan(
      name: name,
      type: widget.type,
      startAmount: startAmount,
      durationDays: durationDays,
      incrementCoeff: coeff,
      monthAmount: monthAmount,
      totalTarget: totalTarget,
      iconCode: _selectedIcon,
      startDate: startDateStr,
    );

    List<SaveRecord> records = [];
    if (widget.type != 'flexible') {
      records = List.generate(
        durationDays,
        (i) {
          final idx = i + 1;
          final dayTarget = SaveProvider.calcDayTarget(
              widget.type, startAmount, idx, coeff, monthAmount);
          final date = _formatDate(
              DateTime(_startDate.year, _startDate.month, _startDate.day)
                  .add(Duration(days: i)));
          return SaveRecord(
            planId: 0,
            sequenceIndex: idx,
            targetAmount: dayTarget,
            savedDate: date,
          );
        },
      );
    }

    final provider = context.read<SaveProvider>();
    final created = await provider.createPlan(plan, records);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              SaveDetailScreen(planId: created.id!),
        ),
        (route) => route.isFirst,
      );
    }
  }
}
