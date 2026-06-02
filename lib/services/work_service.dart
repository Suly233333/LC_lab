import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/agent_repository.dart';
import '../core/work_log_repository.dart';
import '../models/abnormality.dart';
import '../models/agent.dart';
import '../models/work_log.dart';
import '../state/app_providers.dart';
import 'breach_service.dart';

/// 工作执行结果，封装 UI 反馈所需的全部信息。
class WorkOutcome {
  WorkOutcome({
    required this.success,
    required this.isCriticalFail,
    required this.peBoxGained,
    required this.energyDelta,
    required this.qliphothDelta,
    required this.reaction,
    required this.successProbability,
    required this.workType,
    required this.abnormalityId,
    this.breach,
  });

  final bool success;
  final bool isCriticalFail;
  final int peBoxGained;
  final int energyDelta;
  final int qliphothDelta;

  /// 来自 `Abnormality.workReactions[{workType}_{result}]` 的反馈文案。
  final String reaction;
  final double successProbability;
  final String workType;
  final String abnormalityId;

  /// 本次工作引发的突破事件（若有）。
  final BreachEvent? breach;

  bool get isNegativeBefore => false; // 仅作占位扩展位
}

/// 工作执行服务。
///
/// 实现 AGENT.md §2.2 的核心规则：
/// - 成功率 = clamp(weight × aptitude / 10, 0.05, 0.95)
///   - 异想体处于消极状态时 weight ×0.5
/// - 大失败：成功率 < 20% 且判定失败 → qliphothCounter -1
/// - PE Box 产出：成功 floor(weight × aptitude × 2)，失败 0
/// - 能量值：成功 +10 / 失败 -15；消极状态下保底 +5
///   - 能量归零进入消极；恢复至 ≥30 解除消极
/// - HP：成功不变；失败 -5；clamp ≥ 0
/// - 写入 WorkLog 一条记录
class WorkService {
  WorkService({
    required this.ref,
    Random? random,
  }) : _random = random ?? Random();

  final Ref ref;
  final Random _random;

  Future<WorkOutcome> performWork({
    required String abnormalityId,
    required String workType,
  }) async {
    final AbnormalityRepository abnRepo =
        ref.read(abnormalityRepositoryProvider);
    final WorkLogRepository workRepo = ref.read(workLogRepositoryProvider);
    final AgentRepository agentRepo =
        ref.read(agentRepositoryProvider);

    final Abnormality? abn = await abnRepo.getById(abnormalityId);
    if (abn == null) {
      throw StateError('Abnormality $abnormalityId not found');
    }
    final Agent agent = await agentRepo.ensureDefaultUser();
    if (agent.isInjured) {
      // 受伤状态不可工作；上层 UI 应禁止触发。
      throw StateError('Agent is injured');
    }

    final double rawWeight = abn.workTypeWeights[workType] ?? 0.0;
    final double effectiveWeight =
        abn.isNegative ? rawWeight * 0.5 : rawWeight;
    final int aptitude = agent.aptitude[workType] ?? 1;

    final double prob =
        (effectiveWeight * aptitude / 10).clamp(0.05, 0.95).toDouble();

    final double roll = _random.nextDouble();
    final bool success = roll < prob;
    final bool isCriticalFail = !success && prob < 0.20;

    final int peBoxGained =
        success ? (effectiveWeight * aptitude * 2).floor() : 0;

    // 能量值变化 + 消极保底
    int energyDelta;
    if (success) {
      energyDelta = 10;
    } else if (abn.isNegative) {
      energyDelta = 5; // 消极状态下保底 +5
    } else {
      energyDelta = -15;
    }
    final int newEnergyRaw = abn.energyLevel + energyDelta;
    final int newEnergy = newEnergyRaw.clamp(0, 100);
    final int actualEnergyDelta = newEnergy - abn.energyLevel;

    // 计数器变化（大失败 -1）
    int qliphothDelta = 0;
    int newQliphoth = abn.qliphothCounter;
    if (isCriticalFail) {
      qliphothDelta = -1;
      newQliphoth = (abn.qliphothCounter - 1).clamp(0, abn.qliphothMax);
    }

    // HP 变化（失败 -5）
    if (!success) {
      final int newHp = (agent.hp - 5).clamp(0, agent.maxHp);
      await agentRepo.setHp(agent.id, newHp);
    }

    // 持久化能量与计数器
    await abnRepo.setEnergyLevel(abn.id, newEnergy);
    if (qliphothDelta != 0) {
      await abnRepo.setQliphothCounter(abn.id, newQliphoth);
    }

    // 反馈文案
    final String reactionKey = '${workType}_${success ? 'success' : 'fail'}';
    final String reaction =
        abn.workReactions[reactionKey] ?? '（异想体没有任何回应。）';

    // 写入工作记录
    final WorkLog log = WorkLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      abnormalityId: abn.id,
      agentId: agent.id,
      workType: workType,
      success: success,
      isCriticalFail: isCriticalFail,
      peBoxGained: peBoxGained,
      createdAt: DateTime.now(),
    );
    await workRepo.insert(log);

    // PE Box 余额（仅产出时增加）
    if (peBoxGained > 0) {
      await ref.read(peBoxBalanceProvider.notifier).add(peBoxGained);
    }

    // 通知 UI 刷新
    await ref.read(abnormalitiesProvider.notifier).reload();

    // 计数器归零分发突破事件（7.3）。
    BreachEvent? breach;
    if (newQliphoth == 0) {
      breach = await ref.read(breachServiceProvider).maybeBreach(abn.id);
    }

    return WorkOutcome(
      success: success,
      isCriticalFail: isCriticalFail,
      peBoxGained: peBoxGained,
      energyDelta: actualEnergyDelta,
      qliphothDelta: qliphothDelta,
      reaction: reaction,
      successProbability: prob,
      workType: workType,
      abnormalityId: abn.id,
      breach: breach,
    );
  }
}

/// AgentRepository Provider（在此注册以避免循环依赖）。
final agentRepositoryProvider = Provider<AgentRepository>(
  (ref) => AgentRepository(),
);

/// WorkService Provider。
final workServiceProvider = Provider<WorkService>(
  (ref) => WorkService(ref: ref),
);
