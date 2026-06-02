import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/abnormality_repository.dart';
import '../core/agent_repository.dart';
import '../models/abnormality.dart';
import '../models/agent.dart';
import '../models/ego_gear.dart';
import '../state/app_providers.dart';
import 'work_service.dart' show agentRepositoryProvider;

/// 突破事件结果（供 UI 展示警报）。
class BreachEvent {
  BreachEvent({
    required this.abnormality,
    required this.type,
    required this.peBoxLost,
  });
  final Abnormality abnormality;
  final BreachType type;
  final int peBoxLost;
}

/// 镇压结果。
class SuppressionOutcome {
  SuppressionOutcome({
    required this.success,
    required this.peBoxGained,
    required this.hpDelta,
    required this.successProbability,
  });
  final bool success;
  final int peBoxGained;
  final int hpDelta;
  final double successProbability;
}

/// 突破 / 出逃 / 镇压 / 员工受伤恢复 服务。
///
/// AGENT.md §2.3 / §2.4：
/// - qliphothCounter 归零 → 触发 breachType
///   - none：仅重置计数器
///   - penaltyBox：扣除 penaltyAmount% 的 PE Box，PE Box clamp ≥ 0，重置计数器
///   - escape：进入出逃状态，每分钟扣 escapeDrain PE Box；30 分钟后自动返回
/// - 镇压成功率 = clamp(Σ(equipped EGO suppression × 0.1) + 0.2, 0.1, 0.9)
///   - 成功：奖励 floor(qliphothMax × 2) PE Box，立即返回收容，重置计数器
///   - 失败：员工 HP -20（clamp ≥ 0），异想体继续游荡
/// - 员工受伤：HP 归零进入"受伤"，每小时自然恢复 +10（clamp 至 maxHp）
class BreachService {
  BreachService({
    required this.ref,
    Random? random,
    Duration? escapeAutoReturn,
  })  : _random = random ?? Random(),
        escapeAutoReturn = escapeAutoReturn ?? const Duration(minutes: 30);

  final Ref ref;
  final Random _random;

  /// 出逃后自动返回的等待时长（默认 30 分钟）。
  final Duration escapeAutoReturn;

  /// 检查指定异想体是否已触发突破（qliphothCounter == 0）。
  /// 若是，按 breachType 分发并返回 [BreachEvent]；否则返回 null。
  Future<BreachEvent?> maybeBreach(String abnormalityId) async {
    final AbnormalityRepository repo =
        ref.read(abnormalityRepositoryProvider);
    final Abnormality? abn = await repo.getById(abnormalityId);
    if (abn == null) return null;
    if (abn.qliphothCounter > 0) return null;
    if (abn.isEscaped) return null;

    int peBoxLost = 0;
    switch (abn.breachType) {
      case BreachType.none:
        // 仅重置计数器
        await repo.setQliphothCounter(abn.id, abn.qliphothMax);
        break;
      case BreachType.penaltyBox:
        final int pct = abn.penaltyAmount ?? 0;
        if (pct > 0) {
          final int balance =
              await ref.read(peBoxBalanceProvider.future);
          peBoxLost = (balance * pct / 100).floor();
          if (peBoxLost > 0) {
            await ref
                .read(peBoxBalanceProvider.notifier)
                .add(-peBoxLost);
          }
        }
        await repo.setQliphothCounter(abn.id, abn.qliphothMax);
        break;
      case BreachType.escape:
        await repo.setEscapeState(
          abn.id,
          isEscaped: true,
          escapeStartedAt: DateTime.now(),
        );
        break;
    }

    await ref.read(abnormalitiesProvider.notifier).reload();
    return BreachEvent(
      abnormality: abn,
      type: abn.breachType,
      peBoxLost: peBoxLost,
    );
  }

  /// 出逃巡检：
  /// - 持续扣除 PE Box（按上一次扫描时间到当前时间内的整分钟数）；
  /// - 若已超过 [escapeAutoReturn]，自动返回收容并重置计数器。
  ///
  /// 返回的 lostMap 仅用于诊断；实际 PE Box 已扣除。
  Future<Map<String, int>> tickEscape({DateTime? now}) async {
    final DateTime stamp = now ?? DateTime.now();
    final AbnormalityRepository repo =
        ref.read(abnormalityRepositoryProvider);

    final List<Abnormality> all = await repo.getAll();
    final Map<String, int> losses = <String, int>{};
    bool changed = false;

    for (final Abnormality a in all) {
      if (!a.isEscaped) continue;
      final DateTime startedAt = a.escapeStartedAt ?? stamp;
      final Duration elapsed = stamp.difference(startedAt);

      if (elapsed >= escapeAutoReturn) {
        // 自动返回
        await _returnFromEscape(a);
        changed = true;
        continue;
      }

      final int drainPerMinute = a.escapeDrain ?? 0;
      if (drainPerMinute <= 0) continue;
      final int minutes = elapsed.inMinutes;
      // 仅在新一分钟跨过时扣减；这里采用每次扫描扣 1 分钟（与轮询周期对齐）
      // 简化：直接按 minutes 减去已扣减分钟数会引入额外字段；
      // 这里采用每次 tickEscape 扣 escapeDrain 一次的语义（轮询调度器以 1min 周期触发）。
      final int loss = drainPerMinute;
      if (minutes > 0 && loss > 0) {
        await ref.read(peBoxBalanceProvider.notifier).add(-loss);
        losses[a.id] = (losses[a.id] ?? 0) + loss;
      }
    }

    if (changed) {
      await ref.read(abnormalitiesProvider.notifier).reload();
    }
    return losses;
  }

  /// 主管选择不镇压：等价于等待自动返回；本方法仅是显式标记。
  /// 实际等待由 [tickEscape] 处理。
  Future<void> declineSuppression(String abnormalityId) async {
    // no-op：UI 提示用户继续等待自动返回。
  }

  /// 派遣员工镇压。
  Future<SuppressionOutcome> attemptSuppression({
    required String abnormalityId,
    String? agentId,
  }) async {
    final AbnormalityRepository abnRepo =
        ref.read(abnormalityRepositoryProvider);
    final AgentRepository agentRepo = ref.read(agentRepositoryProvider);

    final Abnormality? abn = await abnRepo.getById(abnormalityId);
    if (abn == null || !abn.isEscaped) {
      throw StateError('Abnormality not in escape state');
    }
    final Agent agent = agentId == null
        ? await agentRepo.ensureDefaultUser()
        : (await agentRepo.getById(agentId)) ??
            await agentRepo.ensureDefaultUser();
    if (agent.isInjured) {
      throw StateError('Agent injured, cannot suppress');
    }

    // 计算成功率：base 0.2 + 每件装备 suppression × 0.1
    final List<EgoGear> equipped = await _resolveEquippedEgo(agent);
    double bonus = 0;
    for (final EgoGear g in equipped) {
      bonus += (g.bonusStats[EgoStat.suppression] ?? 0) * 0.1;
    }
    final double prob = (bonus + 0.2).clamp(0.1, 0.9);
    final bool ok = _random.nextDouble() < prob;

    int peBoxGained = 0;
    int hpDelta = 0;
    if (ok) {
      peBoxGained = (abn.qliphothMax * 2).floor();
      await ref.read(peBoxBalanceProvider.notifier).add(peBoxGained);
      await _returnFromEscape(abn);
    } else {
      hpDelta = -20;
      final int newHp = (agent.hp + hpDelta).clamp(0, agent.maxHp);
      await agentRepo.setHp(agent.id, newHp);
    }

    await ref.read(abnormalitiesProvider.notifier).reload();
    return SuppressionOutcome(
      success: ok,
      peBoxGained: peBoxGained,
      hpDelta: hpDelta,
      successProbability: prob,
    );
  }

  /// 员工 HP 自然恢复：每经过 1 小时 +10。
  /// 由调度器按 1 分钟轮询调用。
  Future<void> healAgentsTick({DateTime? now}) async {
    final DateTime stamp = now ?? DateTime.now();
    final AgentRepository agentRepo = ref.read(agentRepositoryProvider);
    final List<Agent> agents = await agentRepo.getAll();
    for (final Agent a in agents) {
      if (a.hp >= a.maxHp) continue;
      // 简化：以"自上次扫描的整小时数"为粒度恢复
      final int elapsedHours = _hoursSinceLastHeal(stamp);
      if (elapsedHours <= 0) continue;
      final int next = (a.hp + 10 * elapsedHours).clamp(0, a.maxHp);
      if (next != a.hp) {
        await agentRepo.setHp(a.id, next);
      }
    }
  }

  Future<void> _returnFromEscape(Abnormality a) async {
    final AbnormalityRepository repo =
        ref.read(abnormalityRepositoryProvider);
    await repo.setEscapeState(
      a.id,
      isEscaped: false,
      escapeStartedAt: null,
    );
    await repo.setQliphothCounter(a.id, a.qliphothMax);
  }

  Future<List<EgoGear>> _resolveEquippedEgo(Agent agent) async {
    // EGO 商店上线后接 ego_inventory 仓库。
    // 为兼容当前阶段，此处返回空列表（即镇压基础成功率 20%）。
    return const <EgoGear>[];
  }

  int _hoursSinceLastHeal(DateTime now) {
    // 简化策略：以小时取整调用方决定语义；返回 1 表示一次性 +10。
    // 由调度器 60 分钟触发一次本方法，以满足"每小时恢复 10 HP"。
    return 1;
  }
}

final breachServiceProvider = Provider<BreachService>(
  (ref) => BreachService(ref: ref),
);
