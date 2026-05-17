import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/app_state.dart';
import '../services/bet_parser.dart';
import 'user_row.dart';

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: AppTheme.buttonHeight,
              child: OutlinedButton(
                onPressed: () => _showAddUserDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                ),
                child: const Text('＋ 添加用户',
                    style: TextStyle(fontSize: AppTheme.bodySize)),
              ),
            ),
            const SizedBox(height: AppTheme.margin),
            if (state.users.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '该日期暂无用户数据，请添加用户',
                  style: TextStyle(
                    fontSize: AppTheme.helperSize,
                    color: AppTheme.textGray,
                  ),
                ),
              )
            else
              ...state.users.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: UserRow(key: ValueKey(user.id), user: user),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ctrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加用户'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: '输入用户名称',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppTheme.textGray),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                        prefixIcon: const Icon(Icons.person_outline,
                            size: 20),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text('粘贴投注内容，系统将自动解析：',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: '例：01,13.25/11 20-30，各100\n或：鼠肖各50\n或：虎兔两肖各100',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppTheme.textGray),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (_) {
                        setDialogState(() => error = null);
                      },
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(error!,
                            style: const TextStyle(
                                color: AppTheme.danger, fontSize: 13)),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                      ),
                      child: const Text(
                          '支持格式：\n'
                          '• 数字：03-04-05-11-14-15-19-31-35-38-39 各20\n'
                          '  （逗号、中文逗号、点、斜杠、减号、空格 全部自动识别）\n'
                          '• 生肖：鼠肖各100、虎兔两肖各50\n'
                          '• 包肖：包马肖50、平肖买牛/羊各30\n'
                          '• 平肖：兔平1500、澳平肖猪3000（只算生肖，不拆分号码）\n'
                          '• 二友/三友/四友/五友：鸡兔二友100\n'
                          '• 固定玩法：特双50、五不中100、红波30 等\n'
                          '• 多行混合输入：每行一种格式，自动合并',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textGray)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      nameCtrl.dispose();
                      ctrl.dispose();
                      Navigator.pop(ctx);
                    },
                    child: const Text('取消')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() => error = '请输入用户名称');
                      return;
                    }
                    final input = ctrl.text.trim();
                    if (input.isEmpty) {
                      setDialogState(() => error = '请输入投注内容');
                      return;
                    }
                    final result = BetParser.parse(input);
                    if (result.hasError) {
                      setDialogState(() => error = result.error);
                      return;
                    }
                    if (result.isEmpty) {
                      setDialogState(() => error = '未能识别投注内容');
                      return;
                    }
                    nameCtrl.dispose();
                    ctrl.dispose();
                    Navigator.pop(ctx);
                    context
                        .read<AppState>()
                        .addUserWithParsing(input, name: name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.white,
                  ),
                  child: const Text('确认添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
