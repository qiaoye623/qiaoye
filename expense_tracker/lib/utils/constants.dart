import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const income = Color(0xFF4CAF50);
  static const expense = Color(0xFFF44336);
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFE0E0E0);
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
