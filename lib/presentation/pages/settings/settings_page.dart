import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xiaozhi_client_flutter/app/themes/wechat_theme.dart';
import 'package:xiaozhi_client_flutter/core/utils/audio_util.dart';
import 'package:xiaozhi_client_flutter/core/utils/xiaozhi_device_info_util.dart';
import '../../../core/providers/theme_provider.dart';

/// 设置页面（微信风格分组卡片）
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSection(
            context,
            isDark,
            title: '设备信息',
            children: [
              WeChatCell(
                leading: const Icon(Icons.confirmation_num_outlined),
                title: const Text('虚拟MAC地址'),
                subtitle: FutureBuilder<String>(
                  future: XiaozhiDeviceInfoUtil.instance.getDeviceMacAddress(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('加载中...');
                    }
                    if (snapshot.hasError) {
                      return const Text('获取失败');
                    }
                    return Text(snapshot.data ?? '未知');
                  },
                ),
                onTap: () async {
                  final macAddress = await XiaozhiDeviceInfoUtil.instance
                      .getDeviceMacAddress();
                  Clipboard.setData(ClipboardData(text: macAddress));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制到剪贴板'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              WeChatCell(
                leading: const Icon(Icons.info_outlined),
                title: const Text('虚拟Client ID'),
                subtitle: FutureBuilder<String>(
                  future: XiaozhiDeviceInfoUtil.instance.getDeviceClientId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('加载中...');
                    }
                    if (snapshot.hasError) {
                      return const Text('获取失败');
                    }
                    return Text(snapshot.data ?? '未知');
                  },
                ),
                onTap: () async {
                  final clientId = await XiaozhiDeviceInfoUtil.instance
                      .getDeviceClientId();
                  Clipboard.setData(ClipboardData(text: clientId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制到剪贴板'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              WeChatCell(
                leading: const Icon(Icons.phone_android_outlined),
                title: const Text('设备型号'),
                subtitle: FutureBuilder<String>(
                  future: XiaozhiDeviceInfoUtil.instance.getDeviceModel(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('加载中...');
                    }
                    if (snapshot.hasError) {
                      return const Text('获取失败');
                    }
                    return Text(snapshot.data ?? '未知');
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            isDark,
            title: '音频能力',
            children: [
              FutureBuilder<Map<String, bool>>(
                future: AudioUtil.checkAudioCapabilities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const WeChatCell(
                      leading: Icon(Icons.graphic_eq),
                      title: Text('音频能力检测'),
                      subtitle: Text('检测中...'),
                    );
                  }

                  final capabilities = snapshot.data ?? {};
                  final aecSupported = capabilities['aecSupported'] ?? false;
                  final noiseSuppress = capabilities['noiseSuppressSupported'] ?? false;
                  final autoGain = capabilities['autoGainSupported'] ?? false;

                  return Column(
                    children: [
                      WeChatCell(
                        leading: Icon(
                          aecSupported ? Icons.check_circle : Icons.cancel,
                          color: aecSupported ? WeChatColors.green : Colors.red,
                        ),
                        title: const Text('AEC 回声消除'),
                        subtitle: Text(aecSupported ? '支持' : '不支持'),
                      ),
                      WeChatCell(
                        leading: Icon(
                          noiseSuppress ? Icons.check_circle : Icons.cancel,
                          color: noiseSuppress ? WeChatColors.green : Colors.red,
                        ),
                        title: const Text('噪声抑制'),
                        subtitle: Text(noiseSuppress ? '支持' : '不支持'),
                      ),
                      WeChatCell(
                        leading: Icon(
                          autoGain ? Icons.check_circle : Icons.cancel,
                          color: autoGain ? WeChatColors.green : Colors.red,
                        ),
                        title: const Text('自动增益控制'),
                        subtitle: Text(autoGain ? '支持' : '不支持'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          _buildSection(
            context,
            isDark,
            title: '外观',
            children: [
              WeChatCell(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('主题模式'),
                subtitle: Text(themeModeNotifier.getThemeModeName()),
                onTap: () {
                  _showThemeDialog(context, ref);
                },
              ),
            ],
          ),
          _buildSection(
            context,
            isDark,
            title: '通用',
            children: [
              WeChatCell(
                leading: const Icon(Icons.language),
                title: const Text('语言'),
                subtitle: const Text('简体中文'),
                onTap: () {
                  // TODO: 切换语言
                },
              ),
              WeChatCell(
                leading: const Icon(Icons.storage),
                title: const Text('清除缓存'),
                onTap: () {
                  // TODO: 清除缓存
                },
              ),
            ],
          ),
          _buildSection(
            context,
            isDark,
            title: '关于',
            children: [
              const WeChatCell(
                leading: Icon(Icons.info_outline),
                title: Text('版本'),
                subtitle: Text('1.0.0'),
              ),
              WeChatCell(
                leading: const Icon(Icons.article_outlined),
                title: const Text('用户协议'),
                onTap: () {
                  // TODO: 显示用户协议
                },
              ),
              WeChatCell(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('隐私政策'),
                onTap: () {
                  // TODO: 显示隐私政策
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 分组：标题 + 白色圆角卡片，行间细分割线
  Widget _buildSection(
    BuildContext context,
    bool isDark,
    {
    required String title,
    required List<Widget> children,
  }) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 16,
            color: isDark ? WeChatColors.dividerDark : WeChatColors.divider,
          ),
        );
      }
      items.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? WeChatColors.textSecondaryDark
                  : WeChatColors.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? WeChatColors.cellBackgroundDark
                : WeChatColors.cellBackground,
            borderRadius: BorderRadius.circular(WeChatDimens.radiusCell),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 显示主题选择对话框
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final currentThemeMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('浅色'),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              activeColor: WeChatColors.green,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色'),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              activeColor: WeChatColors.green,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              activeColor: WeChatColors.green,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
