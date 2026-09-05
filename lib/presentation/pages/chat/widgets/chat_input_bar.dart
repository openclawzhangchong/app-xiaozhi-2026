import 'package:flutter/material.dart';
import '../../../../app/themes/wechat_theme.dart';

/// 聊天输入栏组件（微信风格）
class ChatInputBar extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;
  final VoidCallback onStartVoice;

  const ChatInputBar({
    super.key,
    required this.textController,
    required this.onSendText,
    required this.onPickImage,
    required this.onStartVoice,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? WeChatColors.tabBarBackgroundDark : WeChatColors.fieldBackground;
    final fieldBg = isDark ? WeChatColors.fieldBackgroundDark : Colors.white;
    final iconColor = isDark ? WeChatColors.textSecondaryDark : WeChatColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(
          top: BorderSide(
            color: isDark ? WeChatColors.dividerDark : WeChatColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 语音按钮
            IconButton(
              icon: const Icon(Icons.mic_outlined),
              color: iconColor,
              onPressed: widget.onStartVoice,
              tooltip: '按住说话',
            ),
            // 图片按钮
            IconButton(
              icon: const Icon(Icons.image_outlined),
              color: iconColor,
              onPressed: widget.onPickImage,
              tooltip: '发送图片',
            ),

            // 输入框
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: widget.textController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_hasText) {
                      widget.onSendText();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 4),

            // 发送按钮（有文字时显示绿色）
            IconButton(
              icon: Icon(
                Icons.send,
                color: _hasText
                    ? WeChatColors.green
                    : (isDark ? WeChatColors.textSecondaryDark : WeChatColors.textSecondary),
              ),
              onPressed: _hasText ? widget.onSendText : null,
              tooltip: '发送',
            ),
          ],
        ),
      ),
    );
  }
}
