import 'package:flutter/material.dart';

class SaveTypePopup extends StatelessWidget {
  final void Function(String type) onSelected;

  const SaveTypePopup({super.key, required this.onSelected});

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

  @override
  Widget build(BuildContext context) {
    final types = [
      {'type': '365', 'label': '365天存钱', 'desc': '每天存不同金额，1-365递增'},
      {'type': '52week', 'label': '52周存钱', 'desc': '每周存不同金额，10-520递增'},
      {'type': '12deposit', 'label': '12存单', 'desc': '每月固定金额存12个月'},
      {'type': 'elastic', 'label': '弹性存钱', 'desc': '自定义天数+递增系数'},
      {'type': 'flexible', 'label': '灵活存钱', 'desc': '无规则，随时存任意金额'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('存钱类型',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    color: Color(0xFF999999), size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map((t) => _buildTypeItem(
                context,
                t['type']!,
                t['label']!,
                t['desc']!,
              )),
        ],
      ),
    );
  }

  Widget _buildTypeItem(
      BuildContext context, String type, String label, String desc) {
    final color = _typeColor(type);
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelected(type);
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _shortLabel(type),
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333))),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  String _shortLabel(String type) {
    switch (type) {
      case '365':
        return '365';
      case '52week':
        return '52周';
      case '12deposit':
        return '12月';
      case 'elastic':
        return '弹性';
      case 'flexible':
        return '灵活';
      default:
        return type;
    }
  }
}
