import 'package:flutter/material.dart';

/// 微信风格设计令牌与通用组件。
///
/// 仅做"换皮"：所有颜色取自微信/WeUI 官方设计语言（weui.io 即其门面），
/// 不改变任何业务逻辑、路由与数据流。
class WeChatColors {
  WeChatColors._();

  // ===== 主色 =====
  static const Color green = Color(0xFF07C160); // 微信绿（主/选中/发送）
  static const Color greenPressed = Color(0xFF06AD56);
  static const Color greenLightDark = Color(0xFF4CD07D); // 深色模式下绿色文字
  static const Color link = Color(0xFF576B95); // 链接蓝

  // ===== 页面/聊天背景 =====
  static const Color chatBackground = Color(0xFFEDEDED);
  static const Color pageBackground = Color(0xFFEDEDED);

  // ===== 气泡 =====
  static const Color bubbleUser = Color(0xFF95EC69); // 自己（右侧，绿）
  static const Color bubbleUserDark = Color(0xFF3EB575);
  static const Color bubbleAi = Color(0xFFFFFFFF); // 对方（左侧，白）
  static const Color bubbleAiDark = Color(0xFF2C2C2C);

  // ===== 单元格 / 卡片 / 分隔线 =====
  static const Color cellBackground = Color(0xFFFFFFFF);
  static const Color cellBackgroundDark = Color(0xFF1E1E1E);
  static const Color divider = Color(0xFFE5E5E5);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // ===== 文字 =====
  static const Color textPrimary = Color(0xFF181818);
  static const Color textPrimaryDark = Color(0xFFE5E5E5);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textSecondaryDark = Color(0xFF8C8C8C);
  static const Color timestamp = Color(0xFFB2B2B2);

  // ===== 底部导航栏 =====
  static const Color tabBarBackground = Color(0xFFF7F7F7);
  static const Color tabBarBackgroundDark = Color(0xFF1A1A1A);
  static const Color tabUnselected = Color(0xFF8C8C8C);

  // ===== AppBar =====
  static const Color appBarBackground = Color(0xFFEDEDED);
  static const Color appBarBackgroundDark = Color(0xFF1E1E1E);

  // ===== 输入框 / 灰底 =====
  static const Color fieldBackground = Color(0xFFF7F7F7);
  static const Color fieldBackgroundDark = Color(0xFF2C2C2C);

  /// 根据发送方与深浅色返回气泡颜色
  static Color bubble(bool isUser, bool isDark) =>
      isUser ? (isDark ? bubbleUserDark : bubbleUser) : (isDark ? bubbleAiDark : bubbleAi);
}

/// 微信风格尺寸令牌。
class WeChatDimens {
  WeChatDimens._();
  static const double radiusBubble = 5.0;
  static const double radiusCell = 8.0;
  static const double radiusAvatar = 6.0;
  static const double cellHeight = 56.0;
  static const double tabBarHeight = 56.0;
  static const double horizontalPadding = 16.0;
  static const double navTitleSize = 17.0;
}

/// 微信风格头像：圆角方形，首字母或图标填充。
class WeChatAvatar extends StatelessWidget {
  final String name;
  final bool isUser;
  final bool isDark;
  final double size;

  const WeChatAvatar({
    super.key,
    required this.name,
    required this.isUser,
    required this.isDark,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? WeChatColors.green : const Color(0xFFB0B0B0);
    final initial = name.isNotEmpty ? name[0] : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WeChatDimens.radiusAvatar),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 微信风格列表行（用于设置/对话列表）。
class WeChatCell extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const WeChatCell({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right,
                  color: isDark ? WeChatColors.textSecondaryDark : WeChatColors.textSecondary)
              : null),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: WeChatDimens.horizontalPadding),
      minLeadingWidth: 0,
      horizontalTitleGap: 12,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
    );
  }
}

/// 气泡小尖角（CustomPaint 三角）。
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isUser;

  _BubbleTailPainter(this.color, this.isUser);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isUser) {
      // 右侧尖角，指向右（用户侧）
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height * 0.35);
    } else {
      // 左侧尖角，指向左（AI 侧）
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height * 0.35);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 气泡尖角组件。
class WeChatBubbleTail extends StatelessWidget {
  final Color color;
  final bool isUser;

  const WeChatBubbleTail({
    super.key,
    required this.color,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: CustomPaint(
        painter: _BubbleTailPainter(color, isUser),
        size: const Size(7, 14),
      ),
    );
  }
}
