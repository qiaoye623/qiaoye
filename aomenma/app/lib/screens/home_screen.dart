import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/config_panel.dart';
import '../widgets/user_list_view.dart';
import '../widgets/action_buttons.dart';
import '../widgets/bottom_summary_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            const TopNavBar(),
            // 可滚动内容区
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.padding),
                children: const [
                  ConfigPanel(),
                  SizedBox(height: AppTheme.margin),
                  UserListView(),
                  ActionButtons(),
                  SizedBox(height: 12),
                ],
              ),
            ),
            // 底部汇总栏
            const BottomSummaryBar(),
          ],
        ),
      ),
    );
  }
}
