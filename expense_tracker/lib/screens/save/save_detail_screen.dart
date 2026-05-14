import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/save_provider.dart';
import '../../models/save_plan.dart';
import '../../utils/constants.dart';

class SaveDetailScreen extends StatefulWidget {
  final int planId;

  const SaveDetailScreen({super.key, required this.planId});

  @override
  State<SaveDetailScreen> createState() => _SaveDetailScreenState();
}

class _SaveDetailScreenState extends State<SaveDetailScreen> {
  SavePlan? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<SaveProvider>();
    final plan = await provider.getPlanById(widget.planId);
    await provider.loadRecords(widget.planId);
    if (mounted) {
      setState(() {
        _plan = plan;
        _loading = false;
      });
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
          title: Text(
            _plan?.name ?? '存钱计划',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? const Center(child: Text('计划不存在'))
              : Consumer<SaveProvider>(
                  builder: (context, provider, _) {
                    final records = provider.records;
                    final progress = _plan!.totalTarget > 0
                        ? _plan!.currentAmount /
                            _plan!.totalTarget
                        : 0.0;

                    return Column(
                      children: [
                        _buildStatsHeader(_plan!, progress),
                        Expanded(
                          child: records.isEmpty
                              ? _buildEmptyRecords()
                              : _buildGrid(records),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildStatsHeader(SavePlan plan, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                const Color(0xFF52C41A).withOpacity(0.1),
            child: Text(
              _typeLabel(plan.type),
              style: const TextStyle(
                  color: Color(0xFF52C41A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatAmount(plan.totalTarget),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '已存 ${formatAmount(plan.currentAmount)}',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF52C41A)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '剩余 ${formatAmount(plan.totalTarget - plan.currentAmount)}',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF52C41A)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecords() {
    return const Center(
      child: Text('暂无记录',
          style:
              TextStyle(fontSize: 14, color: Color(0xFF999999))),
    );
  }

  Widget _buildGrid(List records) {
    // 预先计算所有位置的累计金额（到该位置为止已存入的总和）
    final cumulatives = <double>[];
    double runningSum = 0;
    for (final r in records) {
      if (r.status == 'done') {
        runningSum += r.savedAmount;
      }
      cumulatives.add(runningSum);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        final isDone = r.status == 'done';
        // 已存入格子：累计到当前位置；未存入格子：累计到前一个位置（不含自己）
        final cumulativeAmount = cumulatives[index];

        return GestureDetector(
          onTap: () => _toggleRecord(r),
          child: Container(
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF52C41A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF52C41A)
                    : const Color(0xFFEEEEEE),
                width: isDone ? 0 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '存¥${r.targetAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? Colors.white
                        : const Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '累计¥${cumulativeAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDone
                        ? Colors.white70
                        : const Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.savedDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    r.savedDate!,
                    style: TextStyle(
                      fontSize: 8,
                      color: isDone
                          ? Colors.white60
                          : const Color(0xFFCCCCCC),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleRecord(dynamic record) async {
    final provider = context.read<SaveProvider>();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (record.status == 'done') {
      await provider.cancelRecordDone(record.id!, widget.planId);
    } else {
      await provider.markRecordDone(
          record.id!, record.targetAmount, widget.planId, dateStr);
    }
    final updated = await provider.getPlanById(widget.planId);
    if (mounted) {
      setState(() => _plan = updated);
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
}
