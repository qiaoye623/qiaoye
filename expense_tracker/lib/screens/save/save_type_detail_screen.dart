import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/save_provider.dart';
import '../../utils/constants.dart';
import 'save_create_popup.dart';
import 'save_detail_screen.dart';

class SaveTypeDetailScreen extends StatefulWidget {
  final String type;

  const SaveTypeDetailScreen({super.key, required this.type});

  @override
  State<SaveTypeDetailScreen> createState() =>
      _SaveTypeDetailScreenState();
}

class _SaveTypeDetailScreenState
    extends State<SaveTypeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaveProvider>().loadPlans();
    });
  }

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

  String get _typeDesc {
    switch (widget.type) {
      case '365':
        return '每天存入不同金额，按天数序号递增（第n天存n元）。第1天1元→第2天2元→…→第365天365元，坚持365天后，你将拥有66795元！';
      case '52week':
        return '每周存入不同金额，按周数序号递增（第n周存10×n元）。第1周10元→第2周20元→…→第52周520元，坚持52周后，你将拥有13780元！';
      case '12deposit':
        return '每月固定金额，连续存12个月。适合想养成定期储蓄习惯的你，每月100元，12个月后共1200元。';
      case 'elastic':
        return '自定义持续天数和递增系数，每天存入金额递增。灵活设定你的存钱目标，如起始10元，系数2，持续5天：10→12→14→16→18元。';
      case 'flexible':
        return '无规则限制，随时存入任意金额。自由设定存钱计划标题，手动添加存入日期和金额。';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          backgroundColor: const Color(0xFF52C41A),
          title: Text(_typeName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  color: Colors.white, size: 22),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('小程序功能开发中')),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<SaveProvider>(
        builder: (context, provider, _) {
          final filteredPlans = provider.plans
              .where((p) => p.type == widget.type)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_typeName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333))),
                    const SizedBox(height: 8),
                    Text(_typeDesc,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            height: 1.6)),
                    const SizedBox(height: 16),
                    _buildTypeInfo(widget.type),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('存钱计划',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333))),
                  GestureDetector(
                    onTap: () => _showCreatePopup(context),
                    child: const Row(
                      children: [
                        Icon(Icons.add,
                            size: 14, color: Color(0xFF52C41A)),
                        SizedBox(width: 2),
                        Text('存一笔',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF52C41A))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredPlans.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('暂无计划',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999))),
                  ),
                )
              else
                ...filteredPlans.map((plan) => _buildPlanCard(
                    context, plan.id!, plan.name,
                    plan.currentAmount, plan.totalTarget)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeInfo(String type) {
    String info;
    switch (type) {
      case '365':
        info = '目标金额：66795元\n周期：365天';
        break;
      case '52week':
        info = '目标金额：13780元\n周期：52周';
        break;
      case '12deposit':
        info = '周期：12个月\n每月固定金额，可自定义';
        break;
      case 'elastic':
        info = '自定义天数、起始金额、递增系数';
        break;
      case 'flexible':
        info = '无规则限制，自由存入';
        break;
      default:
        info = '';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF52C41A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(info,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF666666))),
    );
  }

  Widget _buildPlanCard(BuildContext context, int planId,
      String name, double saved, double target) {
    final progress = target > 0 ? saved / target : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final provider = context.read<SaveProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaveDetailScreen(planId: planId),
            ),
          ).then((_) => provider.loadPlans());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _typeColor().withOpacity(0.1),
                child: Text(_shortLabel(widget.type),
                    style: TextStyle(
                        color: _typeColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '已存 ${formatAmount(saved)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF52C41A)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ ${formatAmount(target)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            const Color(0xFFEEEEEE),
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
    );
  }

  Color _typeColor() {
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

  String _shortLabel(String type) {
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

  void _showCreatePopup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SaveCreatePopup(type: widget.type),
      ),
    );
  }
}
