import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/themes/wechat_theme.dart';
import '../../../../data/models/message_model.dart';

/// 聊天消息气泡组件（微信风格）
class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  bool get isUser => message.sender == MessageSender.user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = WeChatColors.bubble(isUser, isDark);
    final textColor = isUser
        ? (isDark ? const Color(0xFF0E0E0E) : const Color(0xFF181818))
        : (isDark ? WeChatColors.textPrimaryDark : WeChatColors.textPrimary);

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(WeChatDimens.radiusBubble),
      ),
      child: _buildContentByType(textColor, isDark),
    );

    final tail = WeChatBubbleTail(color: bubbleColor, isUser: isUser);

    final avatar = WeChatAvatar(
      name: isUser ? '我' : 'AI',
      isUser: isUser,
      isDark: isDark,
      size: 38,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            avatar,
            const SizedBox(width: 8),
            Expanded(
              child: _bubbleColumn(bubble, tail),
            ),
          ] else ...[
            Expanded(
              child: _bubbleColumn(bubble, tail),
            ),
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }

  /// 气泡 + 尖角 + 时间戳列
  Widget _bubbleColumn(Widget bubble, Widget tail) {
    // 用户（右）：气泡在左、尖角在右（指向头像）；AI（左）：尖角在左、气泡在右。
    final rowChildren = isUser
        ? [bubble, const SizedBox(width: 2), tail]
        : [tail, const SizedBox(width: 2), bubble];

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: rowChildren,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(
            left: isUser ? 0 : 9,
            right: isUser ? 9 : 0,
          ),
          child: _buildTimestamp(),
        ),
      ],
    );
  }

  /// 根据消息类型构建内容
  Widget _buildContentByType(Color textColor, bool isDark) {
    switch (message.type) {
      case MessageType.text:
        return SelectableText(
          message.content,
          style: TextStyle(fontSize: 16, color: textColor, height: 1.4),
        );

      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: message.content,
            width: 200,
            placeholder: (context, url) => const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );

      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 24, color: textColor),
            const SizedBox(width: 8),
            SelectableText(message.content, style: TextStyle(color: textColor)),
          ],
        );

      case MessageType.system:
        return SelectableText(
          message.content,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? WeChatColors.textSecondaryDark
                : WeChatColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  /// 时间戳
  Widget _buildTimestamp() {
    final time = message.timestamp;
    final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    return Text(
      timeStr,
      style: TextStyle(
        fontSize: 11,
        color: WeChatColors.timestamp,
      ),
    );
  }
}
