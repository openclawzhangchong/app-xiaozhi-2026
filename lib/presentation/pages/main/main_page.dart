import 'package:flutter/material.dart';
import '../../../app/themes/wechat_theme.dart';
import '../conversation/conversation_page.dart';
import '../settings/settings_page.dart';

/// 主页面 - 包含微信风格底部导航栏
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ConversationPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _WeChatTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          _WeChatTabItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: '对话',
          ),
          _WeChatTabItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: '我',
          ),
        ],
        isDark: isDark,
      ),
    );
  }
}

class _WeChatTabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _WeChatTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 微信风格底部标签栏：浅灰底、未选灰、选中绿。
class _WeChatTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_WeChatTabItem> items;
  final bool isDark;

  const _WeChatTabBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? WeChatColors.tabBarBackgroundDark : WeChatColors.tabBarBackground;
    final border = isDark ? WeChatColors.dividerDark : WeChatColors.divider;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: WeChatDimens.tabBarHeight,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              final color = selected
                  ? WeChatColors.green
                  : (isDark ? WeChatColors.tabUnselected : WeChatColors.tabUnselected);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 26,
                        color: color,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
