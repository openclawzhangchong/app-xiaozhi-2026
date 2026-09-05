import 'package:flutter/material.dart';

/// 应用颜色常量（已对齐微信/WeUI 设计语言）。
class AppColors {
  AppColors._();

  // 主色调（微信绿）
  static const Color primary = Color(0xFF07C160);
  static const Color primaryVariant = Color(0xFF06AD56);
  static const Color secondary = Color(0xFF576B95); // 链接蓝
  static const Color secondaryVariant = Color(0xFF4A4458);

  // 背景色
  static const Color background = Color(0xFFEDEDED); // 聊天/列表页灰底
  static const Color backgroundDark = Color(0xFF111111);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // 消息气泡
  static const Color userMessageBg = Color(0xFF95EC69); // 自己（绿）
  static const Color aiMessageBg = Color(0xFFFFFFFF); // 对方（白）
  static const Color userMessageBgDark = Color(0xFF3EB575);
  static const Color aiMessageBgDark = Color(0xFF2C2C2C);

  // 文本颜色
  static const Color textPrimary = Color(0xFF181818);
  static const Color textPrimaryDark = Color(0xFFE5E5E5);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textSecondaryDark = Color(0xFF8C8C8C);

  // 功能色
  static const Color success = Color(0xFF07C160);
  static const Color error = Color(0xFFFA5151); // 微信红
  static const Color warning = Color(0xFFFFC300); // 微信黄
  static const Color info = Color(0xFF576B95);

  // 分割线
  static const Color divider = Color(0xFFE5E5E5);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // 输入框
  static const Color inputBackground = Color(0xFFF7F7F7);
  static const Color inputBackgroundDark = Color(0xFF2C2C2C);
  static const Color inputBorder = Color(0xFFE5E5E5);
  static const Color inputBorderDark = Color(0xFF2C2C2C);
}
