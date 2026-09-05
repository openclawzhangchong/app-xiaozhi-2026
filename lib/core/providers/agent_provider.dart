import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/agent_model.dart';
import '../../data/repositories/agent_repository.dart';
import '../../data/providers/local/agent_local_storage.dart';
import '../storage/storage_service.dart';

/// Agent Repository Provider
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(
    AgentLocalStorage(StorageService.instance),
  );
});

/// Agent List Provider
final agentListProvider =
    AsyncNotifierProvider<AgentListNotifier, List<AgentModel>>(
  AgentListNotifier.new,
);

/// Agent List Notifier
class AgentListNotifier extends AsyncNotifier<List<AgentModel>> {
  late final AgentRepository _repository;

  @override
  Future<List<AgentModel>> build() async {
    _repository = ref.watch(agentRepositoryProvider);
    return await _repository.getAgents();
  }

  /// 加载智能体列表
  Future<void> loadAgents() async {
    state = const AsyncLoading<List<AgentModel>>();
    state = await AsyncValue.guard(() => _repository.getAgents());
  }

  /// 添加智能体
  Future<void> addAgent(AgentModel agent) async {
    try {
      await _repository.saveAgent(agent);
      await loadAgents();
    } catch (e) {
      rethrow;
    }
  }

  /// 更新智能体
  Future<void> updateAgent(AgentModel agent) async {
    try {
      await _repository.updateAgent(agent);
      await loadAgents();
    } catch (e) {
      rethrow;
    }
  }

  /// 删除智能体
  Future<void> deleteAgent(String id) async {
    try {
      await _repository.deleteAgent(id);
      await loadAgents();
    } catch (e) {
      rethrow;
    }
  }

  /// 根据 ID 获取智能体
  Future<AgentModel?> getAgentById(String id) async {
    return await _repository.getAgentById(id);
  }
}
