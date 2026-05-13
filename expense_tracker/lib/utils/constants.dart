import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1677FF);
  static const income = Color(0xFF52C41A);
  static const expense = Color(0xFFF5222D);
  static const background = Color(0xFFF5F7FA);
  static const cardBackground = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF999999);
  static const divider = Color(0xFFEEEEEE);
  static const summaryBg = Color(0xFF1677FF);
}

String formatAmount(double amount) {
  return '¥${amount.toStringAsFixed(2)}';
}

class DefaultCategories {
  static const List<Map<String, String>> expense = [
    {'name': '餐饮', 'icon': '🍽️'},
    {'name': '交通', 'icon': '🚗'},
    {'name': '购物', 'icon': '🛒'},
    {'name': '娱乐', 'icon': '🎮'},
    {'name': '住房', 'icon': '🏠'},
    {'name': '医疗', 'icon': '🏥'},
    {'name': '教育', 'icon': '📚'},
    {'name': '通讯', 'icon': '📱'},
    {'name': '服饰', 'icon': '👔'},
    {'name': '其他支出', 'icon': '📦'},
  ];

  static const List<Map<String, String>> income = [
    {'name': '工资', 'icon': '💰'},
    {'name': '兼职', 'icon': '💼'},
    {'name': '投资', 'icon': '📈'},
    {'name': '红包', 'icon': '🧧'},
    {'name': '其他收入', 'icon': '📥'},
  ];
}
