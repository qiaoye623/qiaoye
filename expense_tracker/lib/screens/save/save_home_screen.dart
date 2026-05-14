import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/save_provider.dart';
import '../../utils/constants.dart';
import 'save_type_popup.dart';
import 'save_type_detail_screen.dart';
import 'save_detail_screen.dart';

class SaveHomeScreen extends StatefulWidget {
  const SaveHomeScreen({super.key});

  @override
  State<SaveHomeScreen> createState() => _SaveHomeScreenState();
}

class _SaveHomeScreenState extends State<SaveHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaveProvider>().loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SaveProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: AppBar(
              backgroundColor: const Color(0xFF52C41A),
              title: Text(
                '存入: ${formatAmount(provider.totalSaved)}',
                style: const TextStyle(
                    fontSize: 14, color: Colors.white),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                _buildStatCol(
                    '目标', formatAmount(provider.totalTarget)),
                Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white38),
                _buildStatCol(
                    '剩余', formatAmount(provider.totalRemaining)),
                const SizedBox(width: 16),
              ],
            ),
          ),
          body: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.plans.isEmpty
                  ? _buildEmptyState()
                  : _buildPlanList(provider),
          floatingActionButton: SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () => _showTypePopup(context),
              backgroundColor: Colors.white,
              shape: CircleBorder(
                side: BorderSide(
                    color: const Color(0xFF52C41A).withOpacity(0.3)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline,
                      color: Color(0xFF52C41A), size: 20),
                  Text('存一笔',
                      style: TextStyle(
                          color: Color(0xFF52C41A),
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildStatCol(String label, String amount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.white70)),
        Text(amount,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined,
              size: 80, color: Color(0xFFEEEEEE)),
          SizedBox(height: 12),
          Text('暂无数据',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildPlanList(SaveProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: provider.plans.length,
      itemBuilder: (context, index) {
        final plan = provider.plans[index];
        final progress = plan.totalTarget > 0
            ? plan.currentAmount / plan.totalTarget
            : 0.0;
        return Dismissible(
          key: Key('plan_${plan.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('确认删除'),
                content: const Text('确定要删除这个存钱计划吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('删除',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            provider.deletePlan(plan.id!);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SaveDetailScreen(planId: plan.id!),
                  ),
                ).then((_) => provider.loadPlans());
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _typeColor(plan.type).withOpacity(0.1),
                      child: Text(
                        _typeLabel(plan.type),
                        style: TextStyle(
                            color: _typeColor(plan.type),
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(plan.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '已存 ${formatAmount(plan.currentAmount)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF52C41A)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '/ ${formatAmount(plan.totalTarget)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(
                                  0xFFEEEEEE),
                              valueColor:
                                  const AlwaysStoppedAnimation(
                                      Color(0xFF52C41A)),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
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

  String _typeLabel(String type) {
    switch (type) {
      case '365':
        return '365';
      case '52week':
        return '52';
      case '12deposit':
        return '12';
      case 'elastic':
        return '弹性';
      case 'flexible':
        return '灵活';
      default:
        return type;
    }
  }

  void _showTypePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SaveTypePopup(
        onSelected: (type) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaveTypeDetailScreen(type: type),
            ),
          );
        },
      ),
    );
  }
}
