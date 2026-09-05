import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xiaozhi_client_flutter/core/network/xiaozhi_ota_service.dart';
import 'package:xiaozhi_client_flutter/core/network/xiaozhi_websocket_manager.dart';
import 'package:xiaozhi_client_flutter/core/providers/agent_provider.dart';
import 'package:xiaozhi_client_flutter/core/utils/audio_util.dart';
import 'package:xiaozhi_client_flutter/core/utils/xiaozhi_device_info_util.dart';
import 'package:xiaozhi_client_flutter/data/models/agent_model.dart';
import '../../../data/models/message_model.dart';
import '../../../core/utils/toast_util.dart';
import 'widgets/message_list.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/voice_record_button.dart';
import 'package:logging/logging.dart';

/// 聊天页面
class ChatPage extends ConsumerStatefulWidget {
  final String agentId;
  final String agentName;

  const ChatPage({super.key, required this.agentId, required this.agentName});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final Logger logger = Logger('ChatScreen');
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _showVoiceButton = false;
  AgentModel? _currentAgent;

  // WebSocket 相关
  XiaozhiWebSocketManager? _wsManager;
  bool _isConnected = false;
  String _connectionStatus = '未连接';
  String? _sessionId;

  // OTA 认证信息
  XiaozhiOtaService? _otaService;

  // AI 播放状态跟踪
  bool _isAiPlaying = false;
  Timer? _aiPlayingTimer; // 用于检测播放结束的定时器

  @override
  void initState() {
    super.initState();
    _loadAgent();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _aiPlayingTimer?.cancel();
    _cleanupWebSocket();
    _otaService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态栏（仅在非连接状态时显示）
          if (!_isConnected)
            _buildConnectionStatusBar(),

          // 消息列表
          Expanded(
            child: MessageList(
              messages: _messages,
              scrollController: _scrollController,
            ),
          ),

          // 输入区域（根据模式显示不同的组件）
          if (_showVoiceButton)
            _buildVoiceInputArea()
          else
            ChatInputBar(
              textController: _textController,
              onSendText: _sendTextMessage,
              onPickImage: _pickImage,
              onStartVoice: () {
                setState(() {
                  _showVoiceButton = true;
                });
              },
            ),
        ],
      ),
    );
  }

  /// 连接状态栏
  Widget _buildConnectionStatusBar() {
    Color statusColor;
    IconData statusIcon;
    String statusText = _connectionStatus;

    // 根据连接状态设置颜色和图标
    if (_isConnected) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_connectionStatus == '正在连接...' || _connectionStatus == '正在认证...') {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 断线时显示重连按钮
          if (!_isConnected && 
              _connectionStatus != '正在连接...' && 
              _connectionStatus != '正在认证...')
            TextButton.icon(
              onPressed: _reconnect,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重连'),
              style: TextButton.styleFrom(
                foregroundColor: statusColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  /// 重新连接
  Future<void> _reconnect() async {
    if (_connectionStatus == '正在连接...' || _connectionStatus == '正在认证...') {
      return; // 正在连接中，不重复连接
    }

    ToastUtil.show('正在重新连接...');
    
    // 清理旧连接
    await _cleanupWebSocket();
    
    // 重新初始化 WebSocket
    await _initializeWebSocket();
  }

  /// 语音输入区域
  Widget _buildVoiceInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 切换回文本输入按钮
            IconButton(
              icon: const Icon(Icons.keyboard),
              onPressed: () {
                setState(() {
                  _showVoiceButton = false;
                });
              },
              tooltip: '切换到文本输入',
            ),

            // 按住说话按钮
            Expanded(
              child: VoiceRecordButton(
                onRecordStart: _handleAudioStart,
                onAudioSend: _handleAudioSend,
                onRecordEnd: _handleAudioStop,
                onRecordCancel: _onRecordCancel,
                onContinuousListenStart: _handleContinuousListenStart,
                onContinuousListenStop: _handleContinuousListenStop,
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// 发送文本消息
  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 调用接口发送消息
    _wsManager?.sendTextRequest(text);

    _textController.clear();
    _scrollToBottom();
  }

  void _appendOrCreateChatMessage(MessageSender role, String content) {
    if (role == MessageSender.system) {
      return;
    }
    final targetSender = role == MessageSender.ai
        ? MessageSender.ai
        : MessageSender.user;

    // 检查最后一条消息是否与当前角色相同
    if (_messages.isNotEmpty && _messages.last.sender == targetSender) {
      // 最后一条消息角色相同，追加内容
      setState(() {
        final lastMessage = _messages.last;
        final updatedMessage = MessageModel(
          id: lastMessage.id,
          agentId: lastMessage.agentId,
          type: lastMessage.type,
          content: lastMessage.content + content,
          sender: lastMessage.sender,
          status: lastMessage.status,
          timestamp: lastMessage.timestamp,
        );
        _messages[_messages.length - 1] = updatedMessage;
      });
    } else {
      // 最后一条消息角色不同或列表为空，创建新消息
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        agentId: widget.agentId,
        type: MessageType.text,
        content: content,
        sender: targetSender,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(message);
      });
    }

    _scrollToBottom();
  }

  /// 选择图片
  void _pickImage() {
    // TODO: 实现图片选择
    ToastUtil.show('图片功能开发中');
  }

  /// 取消录音
  void _onRecordCancel() {
    ToastUtil.show('已取消录音');
  }

  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('清空聊天记录'),
              onTap: () {
                Navigator.pop(context);
                _clearMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('智能体设置'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转到智能体配置页面
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 清空消息
  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
    ToastUtil.success('已清空聊天记录');
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// 加载智能体数据（编辑模式）
  Future<void> _loadAgent() async {
    final agent = await ref
        .read(agentListProvider.notifier)
        .getAgentById(widget.agentId);

    if (agent != null) {
      setState(() {
        _currentAgent = agent;
        // 初始化 OTA 服务，使用 Agent 的 otaUrl
        _otaService = XiaozhiOtaService(
          otaUrl: agent.otaUrl.isNotEmpty
              ? agent.otaUrl
              : 'https://api.tenclass.net/xiaozhi/ota/',
        );
      });
      // Agent 加载完成后，初始化 WebSocket
      _initializeWebSocket();
    } else {
      // 如果智能体不存在，返回智能体列表页面
      if (mounted) {
        context.go('/');
      }
    }
  }

  /// 清理 WebSocket 连接
  Future<void> _cleanupWebSocket() async {
    if (_wsManager != null) {
      await _wsManager!.disconnect();
      _wsManager = null;
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 执行 OTA 认证获取 WebSocket 连接信息
  Future<bool> _performOtaAuthentication() async {
    try {
      setState(() {
        _connectionStatus = '正在认证...';
      });

      logger.info('开始 OTA 认证...');

      // 确保 OTA 服务已初始化
      if (_otaService == null) {
        logger.severe('OTA 服务未初始化');
        _showError('OTA 服务未初始化');
        return false;
      }

      // 调用 OTA API 获取 WebSocket 信息
      final otaResponse = await _otaService!.checkFlutterAppUpdates(
        appName: 'ajb_agent_flutter',
        appVersion: '1.0.0',
        acceptLanguage: 'zh-CN',
      );

      // 检查是否返回了 WebSocket 信息
      if (otaResponse.websocket != null) {
        if (otaResponse.activation != null) {
          final code = otaResponse.activation!.code;
          _appendOrCreateChatMessage(
            MessageSender.ai,
            '设备需要在平台端注册，注册码:[$code]，注册成功后需重新进入对话',
          );
          _showError('认证失败: 设备未注册');
          setState(() {
            _connectionStatus = '认证失败';
          });
          return false;
        }

        logger.info('OTA 认证成功');
        return true;
      } else {
        logger.warning('OTA 响应中没有 WebSocket 信息');
        _showError('认证失败: 服务器未返回连接信息');
        setState(() {
          _connectionStatus = '认证失败';
        });
        return false;
      }
    } on OtaException catch (e) {
      logger.severe('OTA 认证失败: ${e.message}');
      _showError('认证失败: ${e.message}');
      setState(() {
        _connectionStatus = '认证失败';
      });
      return false;
    } catch (e, stackTrace) {
      logger.severe('OTA 认证异常: $e\n$stackTrace');
      _showError('认证异常: $e');
      setState(() {
        _connectionStatus = '认证异常';
      });
      return false;
    }
  }

  /// 初始化 WebSocket 连接
  Future<void> _initializeWebSocket() async {
    if (_currentAgent == null) {
      logger.warning('当前智能体为空，无法初始化 WebSocket');
      return;
    }

    try {
      // 第一步: 执行 OTA 认证
      final authSuccess = await _performOtaAuthentication();
      if (!authSuccess) {
        logger.warning('OTA 认证失败,取消 WebSocket 连接');
        return;
      }

      // 第二步: 获取设备ID
      final deviceId = await XiaozhiDeviceInfoUtil.instance
          .getDeviceMacAddress();

      print(_currentAgent);
      // 第三步: 创建 WebSocket 管理器
      _wsManager = XiaozhiWebSocketManager(
        deviceId: deviceId,
        enableToken: false,
      );

      // 第四步: 添加事件监听器
      _wsManager!.addListener(_handleWebSocketEvent);

      // 第五步: 使用Agent配置 wsUrl 和 wsToken 连接服务器
      await _connectToWebSocket(_currentAgent?.url ?? '', 'test-token');
    } catch (e) {
      logger.severe('初始化 WebSocket 失败: $e');
      _showError('连接初始化失败: $e');
    }
  }

  /// 使用指定的 URL 和 Token 连接 WebSocket
  Future<void> _connectToWebSocket(String url, String token) async {
    if (_wsManager == null) return;

    setState(() {
      _connectionStatus = '正在连接...';
    });

    try {
      await _wsManager!.connect(url, token);
      logger.info('WebSocket 连接请求已发送');
    } catch (e) {
      logger.severe('WebSocket 连接失败: $e');
      setState(() {
        _connectionStatus = '连接失败';
      });
      _showError('连接失败: $e');
    }
  }

  /// 处理 WebSocket 事件
  void _handleWebSocketEvent(XiaozhiEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case XiaozhiEventType.connected:
        setState(() {
          _isConnected = true;
          _connectionStatus = '已连接';
        });
        logger.info('WebSocket 已连接');
        //_addConnectionStatusMessage('已连接到服务器');
        break;

      case XiaozhiEventType.disconnected:
        setState(() {
          _isConnected = false;
          _connectionStatus = '已断开';
        });
        logger.info('WebSocket 已断开');
        //_addConnectionStatusMessage('与服务器断开连接');
        break;

      case XiaozhiEventType.message:
        _handleTextMessage(event.data as String);
        break;

      case XiaozhiEventType.binaryMessage:
        _handleBinaryMessage(event.data as List<int>);
        break;

      case XiaozhiEventType.error:
        logger.severe('WebSocket 错误: ${event.data}');
        _showError('连接错误: ${event.data}');
        break;
    }
  }

  /// 处理二进制消息（音频数据）
  void _handleBinaryMessage(List<int> data) {
    //logger.info('收到音频数据: ${data.length} 字节');
    
    // 标记 AI 开始播放
    if (!_isAiPlaying) {
      setState(() {
        _isAiPlaying = true;
      });
      logger.info('AI 开始播放音频，暂停发送麦克风数据');
    }
    
    // 重置定时器，如果一段时间没有收到新的音频数据，则认为播放结束
    _aiPlayingTimer?.cancel();
    _aiPlayingTimer = Timer(const Duration(milliseconds: 500), () {
      // 500ms 没有收到新的音频数据，认为播放结束
      if (_isAiPlaying) {
        setState(() {
          _isAiPlaying = false;
        });
        logger.info('AI 播放结束，恢复发送麦克风数据');
      }
    });
    
    // 播放音频
    AudioUtil.playOpusData(Uint8List.fromList(data));
  }

  /// 处理文本消息
  void _handleTextMessage(String message) {
    try {
      // 解析 JSON 消息
      final jsonData = Map<String, dynamic>.from(
        const JsonDecoder().convert(message),
      );

      final type = jsonData['type'] as String?;

      switch (type) {
        case 'tts':
          // 处理 TTS 消息
          final state = jsonData['state'] as String?;
          final text = jsonData['text'] as String?;

          if (state == 'sentence_start' && text != null && text.isNotEmpty) {
            // AI 开始说新的一句话，追加到当前消息
            _appendOrCreateChatMessage(MessageSender.ai, text);
          } else if (state == 'end') {
            // AI 说完了，标记播放结束
            _aiPlayingTimer?.cancel();
            if (_isAiPlaying) {
              setState(() {
                _isAiPlaying = false;
              });
              logger.info('TTS 结束，AI 播放完成，恢复发送麦克风数据');
            }
          }
          break;

        case 'stt':
          // 处理语音识别结果 - 实时追加到最后一条用户消息
          final text = jsonData['text'] as String?;
          if (text != null && text.isNotEmpty) {
            logger.info('语音识别: $text');
            _appendOrCreateChatMessage(MessageSender.user, text);
            _scrollToBottom();
          }
          break;

        case 'hello':
          // 🔥 服务器 hello 响应，提取 session_id
          final sessionId = jsonData['session_id'] as String?;
          if (sessionId != null && sessionId.isNotEmpty) {
            _sessionId = sessionId;
            logger.info('收到服务器 hello 响应，会话ID: $_sessionId');
          } else {
            logger.info('收到服务器 hello 响应（无 session_id）');
          }
          break;

        case 'mcp':

          /// todo:处理 MCP 消息

          break;

        default:
          logger.warning('未知消息类型: $type , 内容: $message');
      }
    } catch (e) {
      logger.severe('解析消息失败: $e');
    }
  }

  /// 处理音频数据发送（发送二进制音频数据）
  void _handleAudioSend(Uint8List audioData) {
    // 如果 AI 正在播放，则不发送音频数据（但录音继续）
    if (_isAiPlaying) {
      // logger.info('AI 正在播放，跳过发送音频数据'); // 注释掉，避免日志过多
      return;
    }
    
    // 通过 WebSocket 发送音频数据
    if (_wsManager != null && _isConnected) {
      try {
        _wsManager!.sendBinaryMessage(audioData);
        // logger.info('已发送音频数据: ${audioData.length} 字节'); // 注释掉，避免日志过多
      } catch (e) {
        logger.severe('发送音频失败: $e');
        _showError('发送音频失败: $e');
      }
    } else {
      _showError('未连接到服务器，请检查网络连接');
    }
  }

  /// 处理音频停止（发送 listen stop 消息）
  void _handleAudioStop() {
    if (_wsManager == null || !_isConnected) {
      return;
    }

    try {
      // 🔥 发送 listen stop 消息（按照协议）
      final listenStopMessage = {
        "session_id": _sessionId ?? "", // 使用从 hello 消息中获取的 session_id
        "type": "listen",
        "mode": "auto",
        "state": "stop",
      };

      _wsManager!.sendMessage(jsonEncode(listenStopMessage));
      logger.info('已发送 listen stop 消息: ${jsonEncode(listenStopMessage)}');
    } catch (e) {
      logger.severe('发送 listen stop 消息失败: $e');
    }
  }

  /// 处理音频开始（发送 listen start 消息）
  void _handleAudioStart() {
    if (_wsManager == null || !_isConnected) {
      _showError('未连接到服务器');
      return;
    }

    try {
      // 🔥 发送 listen start 消息（按照协议）
      final listenStartMessage = {
        "session_id": _sessionId ?? "", // 使用从 hello 消息中获取的 session_id
        "type": "listen",
        "state": "start",
        "mode": "auto", // 自动模式：自动识别说话
      };

      _wsManager!.sendMessage(jsonEncode(listenStartMessage));
      logger.info('已发送 listen start 消息: ${jsonEncode(listenStartMessage)}');
    } catch (e) {
      logger.severe('发送 listen start 消息失败: $e');
      _showError('启动录音失败: $e');
    }
  }

  /// 处理持续监听开始（发送 realtime 模式的 listen start 消息）
  void _handleContinuousListenStart() {
    if (_wsManager == null || !_isConnected) {
      _showError('未连接到服务器');
      return;
    }

    try {
      // 🔥 发送 realtime 模式的 listen start 消息
      final listenStartMessage = {
        "session_id": _sessionId ?? "",
        "type": "listen",
        "state": "start",
        "mode": "realtime", // 实时模式：持续监听
      };

      _wsManager!.sendMessage(jsonEncode(listenStartMessage));
      logger.info('已发送持续监听 start 消息: ${jsonEncode(listenStartMessage)}');
      ToastUtil.show('开始持续监听');
    } catch (e) {
      logger.severe('发送持续监听 start 消息失败: $e');
      _showError('启动持续监听失败: $e');
    }
  }

  /// 处理持续监听停止（发送 realtime 模式的 listen stop 消息）
  void _handleContinuousListenStop() {
    if (_wsManager == null || !_isConnected) {
      return;
    }

    try {
      // 🔥 发送 realtime 模式的 listen stop 消息
      final listenStopMessage = {
        "session_id": _sessionId ?? "",
        "type": "listen",
        "state": "stop",
        "mode": "realtime", // 实时模式：持续监听
      };

      _wsManager!.sendMessage(jsonEncode(listenStopMessage));
      logger.info('已发送持续监听 stop 消息: ${jsonEncode(listenStopMessage)}');
      ToastUtil.show('停止持续监听');
    } catch (e) {
      logger.severe('发送持续监听 stop 消息失败: $e');
    }
  }
}
