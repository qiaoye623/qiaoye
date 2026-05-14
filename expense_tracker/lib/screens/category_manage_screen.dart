import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../utils/constants.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseHelper();
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  bool _loading = true;

  static const _defaultExpenseNames = {
    '餐饮', '交通', '购物', '娱乐', '住房', '医疗', '教育', '通讯', '服饰', '其他支出',
  };
  static const _defaultIncomeNames = {
    '工资', '兼职', '投资', '红包', '其他收入',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final expense = await _db.getCategories('expense');
    final income = await _db.getCategories('income');
    if (mounted) {
      setState(() {
        _expenseCategories = expense;
        _incomeCategories = income;
        _loading = false;
      });
    }
  }

  bool _isDefault(Category cat) {
    if (cat.type == 'expense') {
      return _defaultExpenseNames.contains(cat.name);
    }
    return _defaultIncomeNames.contains(cat.name);
  }

  void _showAddDialog(String type) async {
    final nameCtrl = TextEditingController();
    final icons = ['🍽️', '🚗', '🛒', '🎮', '🏠', '🏥', '📚', '📱', '👔', '📦', '💰', '💼', '📈', '🧧', '📥', '✈️', '🐱', '🎵', '📷', '💻'];
    String selectedIcon = icons[0];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加分类'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '分类名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('选择图标', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icons.map((icon) {
                      final selected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF1677FF).withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: selected ? Border.all(color: const Color(0xFF1677FF)) : null,
                          ),
                          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
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
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, {'name': nameCtrl.text.trim(), 'icon': selectedIcon});
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _db.insertCategory(Category(
        name: result['name']!,
        icon: result['icon']!,
        type: type,
      ));
      await _loadCategories();
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除"${cat.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定', style: TextStyle(color: Color(0xFFF5222D)))),
        ],
      ),
    );
    if (confirm == true && cat.id != null) {
      await _db.deleteCategory(cat.id!);
      await _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: const Text('分类管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1677FF),
                    unselectedLabelColor: const Color(0xFF999999),
                    indicatorColor: const Color(0xFF1677FF),
                    tabs: const [
                      Tab(text: '支出'),
                      Tab(text: '收入'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryList(_expenseCategories, 'expense'),
                      _buildCategoryList(_incomeCategories, 'income'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无分类', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(type),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加分类'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text('共 ${categories.length} 个分类',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddDialog(type),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF1677FF)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isDefault = _isDefault(cat);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Text(cat.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(cat.name, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  trailing: isDefault
                      ? const Text('默认', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFF5222D)),
                          onPressed: () => _deleteCategory(cat),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
