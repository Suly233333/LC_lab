import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/agent_repository.dart';
import '../core/ego_repository.dart';
import '../core/preset_loader.dart';
import '../models/agent.dart';
import '../models/ego_gear.dart';
import '../state/app_providers.dart';
import 'work_service.dart' show agentRepositoryProvider;

/// EGO 商店与员工装备穿脱服务。
class EgoShopService {
  EgoShopService({required this.ref});
  final Ref ref;

  /// 加载装备目录（来自 assets）。
  Future<List<EgoGear>> loadCatalog() => PresetLoader.loadEgoGears();

  /// 加载已拥有的装备 ID 集合。
  Future<Set<String>> ownedIds() async {
    final List<EgoGear> all =
        await ref.read(egoRepositoryProvider).getAll();
    return all.map((g) => g.id).toSet();
  }

  /// 兑换：扣 PE Box（不足则返回 false），写入库存。
  Future<bool> purchase(EgoGear gear) async {
    final int balance =
        await ref.read(peBoxBalanceProvider.future);
    if (balance < gear.cost) return false;

    final EgoRepository egoRepo = ref.read(egoRepositoryProvider);
    final EgoGear? exists = await egoRepo.getById(gear.id);
    if (exists != null) return false; // 已拥有，不重复扣费

    await ref.read(peBoxBalanceProvider.notifier).add(-gear.cost);
    await egoRepo.insert(gear);
    return true;
  }

  /// 主管员工穿戴某件装备。
  Future<void> equip(String agentId, String egoId) async {
    final AgentRepository agentRepo =
        ref.read(agentRepositoryProvider);
    final Agent? agent = await agentRepo.getById(agentId);
    if (agent == null) return;
    if (agent.equippedEgoIds.contains(egoId)) return;
    final List<String> next = [...agent.equippedEgoIds, egoId];
    await agentRepo.equip(agent.id, next);
  }

  /// 主管员工脱下某件装备。
  Future<void> unequip(String agentId, String egoId) async {
    final AgentRepository agentRepo =
        ref.read(agentRepositoryProvider);
    final Agent? agent = await agentRepo.getById(agentId);
    if (agent == null) return;
    final List<String> next =
        agent.equippedEgoIds.where((id) => id != egoId).toList();
    await agentRepo.equip(agent.id, next);
  }
}

final egoRepositoryProvider = Provider<EgoRepository>(
  (ref) => EgoRepository(),
);

final egoShopServiceProvider = Provider<EgoShopService>(
  (ref) => EgoShopService(ref: ref),
);
