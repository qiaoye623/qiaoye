import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'asset_account_screen.dart';
import 'save/save_home_screen.dart';
import 'qr_code_screen.dart';
import 'category_manage_screen.dart';
import 'annual_bill_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: const Text('我的', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 22, color: Color(0xFF333333)),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildGroup(context, '功能', [
            {'icon': Icons.savings_outlined, 'label': '存钱'},
            {'icon': Icons.auto_stories_outlined, 'label': '写日记'},
          ]),
          const SizedBox(height: 12),
          _buildGroup(context, '设置', [
            {'icon': Icons.email_outlined, 'label': '设置邮箱'},
            {'icon': Icons.lock_outlined, 'label': '设置密码'},
            {'icon': Icons.category_outlined, 'label': '分类管理'},
            {'icon': Icons.account_balance_wallet_outlined, 'label': '资产账户'},
          ]),
          const SizedBox(height: 12),
          _buildGroup(context, '数据', [
            {'icon': Icons.download_outlined, 'label': '导出账单'},
            {'icon': Icons.upload_outlined, 'label': '导入账单'},
            {'icon': Icons.bar_chart_outlined, 'label': '年度账单'},
          ]),
          const SizedBox(height: 12),
          _buildGroup(context, '其他', [
            {'icon': Icons.wechat_outlined, 'label': '关注公众号'},
            {'icon': Icons.share_outlined, 'label': '分享给好友'},
            {'icon': Icons.headset_mic_outlined, 'label': '联系客服'},
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF1677FF),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('未登录',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                SizedBox(height: 4),
                Text('记账0天·共0笔',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22, color: Color(0xFF333333)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String title, List<Map> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
                  GestureDetector(
                    onTap: () => _onItemTap(context, item['label'] as String),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, size: 22, color: const Color(0xFF333333)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(item['label'] as String,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF999999)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _onItemTap(BuildContext context, String label) {
    switch (label) {
      case '存钱':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const SaveHomeScreen()),
        );
        break;
      case '资产账户':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssetAccountScreen()),
        );
        break;
      case '分类管理':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryManageScreen()),
        );
        break;
      case '关注公众号':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const QrCodeScreen(
                    imagePath: 'assets/gongzhaohao.jpg',
                    title: '关注公众号',
                  )),
        );
        break;
      case '联系客服':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const QrCodeScreen(
                    imagePath: 'assets/lianxikefu.jpg',
                    title: '联系客服',
                  )),
        );
        break;
      case '年度账单':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnualBillScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 功能开发中')),
        );
    }
  }
}
