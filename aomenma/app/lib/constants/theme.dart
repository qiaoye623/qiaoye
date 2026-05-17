import 'package:flutter/material.dart';

class AppTheme {
  // 主色
  static const Color primary = Color(0xFF1677FF);
  static const Color background = Color(0xFFF3F4F6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textGray = Color(0xFF9CA3AF);

  // 尺寸
  static const double navBarHeight = 50.0;
  static const double bottomBarHeight = 60.0;
  static const double inputHeight = 44.0;
  static const double buttonHeight = 44.0;
  static const double minTouchSize = 44.0;
  static const double radius = 6.0;
  static const double padding = 10.0;
  static const double margin = 10.0;

  // 字体
  static const double titleSize = 18.0;
  static const double bodySize = 16.0;
  static const double helperSize = 14.0;

  // 阴影
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
}
