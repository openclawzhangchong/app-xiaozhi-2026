import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/wechat_theme.dart';
import '../../../core/providers/agent_provider.dart';

/// 对话页面 - 智能体列表（微信通讯录风格）
class ConversationPage extends ConsumerWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentListAsync = ref.watch(agentListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('对话'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push(AppRoutes.agentConfig);
            },
            tooltip: '添加智能体',
          ),
        ],
      ),
      body: agentListAsync.when(
        data: (agents) {
          if (agents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无智能体',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击右上角 "+" 添加智能体',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.agentConfig);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('添加智能体'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: agents.length,
            separatorBuilder: (context, index) => const Divider(
              height: 0.5,
              thickness: 0.5,
              color: WeChatColors.divider,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final agent = agents[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return InkWell(
                onTap: () {
                  context.push(
                    '${AppRoutes.chat}?agentId=${agent.id}&agentName=${agent.name}',
                  );
                },
                child: Container(
                  color: isDark ? WeChatColors.cellBackgroundDark : WeChatColors.cellBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      WeChatAvatar(
                        name: agent.name,
                        isUser: false,
                        isDark: isDark,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: WeChatColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (agent.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                agent.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? WeChatColors.textSecondaryDark
                                      : WeChatColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.grey),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('编辑'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('删除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            context.push(
                              '${AppRoutes.agentConfig}?agentId=${agent.id}',
                            );
                          } else if (value == 'delete') {
                            _showDeleteDialog(context, ref, agent.id, agent.name);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(agentListProvider.notifier).loadAgents();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String agentId,
    String agentName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除智能体'),
        content: Text('确定要删除 "$agentName" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(agentListProvider.notifier).deleteAgent(agentId);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
