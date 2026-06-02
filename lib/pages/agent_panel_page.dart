import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/agent_repository.dart';
import '../core/ego_repository.dart';
import '../core/theme.dart';
import '../models/agent.dart';
import '../models/ego_gear.dart';
import '../services/ego_shop_service.dart';
import '../services/work_service.dart' show agentRepositoryProvider;
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';
import 'ego_shop_page.dart';

/// 主管员工详情面板。
///
/// 展示 HP / 受伤状态 / 四维适性 / 已装备 EGO；支持装备穿脱。
class AgentPanelPage extends ConsumerStatefulWidget {
  const AgentPanelPage({super.key});

  @override
  ConsumerState<AgentPanelPage> createState() => _AgentPanelPageState();
}

class _AgentPanelPageState extends ConsumerState<AgentPanelPage> {
  Future<_AgentPanelData>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final AgentRepository agentRepo =
        ref.read(agentRepositoryProvider);
    final EgoRepository egoRepo = ref.read(egoRepositoryProvider);
    _future = _AgentPanelData.load(agentRepo: agentRepo, egoRepo: egoRepo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AGENT PANEL'),
        actions: [
          IconButton(
            tooltip: 'EGO SHOP',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.of(context)
                .push<void>(MaterialPageRoute(
                    builder: (_) => const EgoShopPage()))
                .then((_) => setState(_refresh)),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: FutureBuilder<_AgentPanelData>(
              future: _future,
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                return _buildBody(snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(_AgentPanelData data) {
    final Agent a = data.agent;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentityCard(a),
          const SizedBox(height: 16),
          _buildAptitudeCard(a),
          const SizedBox(height: 16),
          _buildInventoryCard(data),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(Agent a) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.name,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (a.isInjured)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.alert),
                  ),
                  child: const Text(
                    'INJURED',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.alert,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'HP',
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  color: AppColors.alert,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: a.hp / a.maxHp,
                  minHeight: 10,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    a.isInjured
                        ? AppColors.danger
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${a.hp}/${a.maxHp}',
                style: const TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAptitudeCard(Agent a) {
    final List<MapEntry<String, int>> entries = a.aptitude.entries.toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// APTITUDE',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.primary, width: 1),
                      ),
                      child: Text(
                        '${e.key.toUpperCase()}  ${e.value}',
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          color: AppColors.onBackground,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(_AgentPanelData data) {
    final Set<String> equippedIds = data.agent.equippedEgoIds.toSet();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// EGO INVENTORY',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (data.inventory.isEmpty)
            const Text(
              '// 库存为空 — 前往 EGO SHOP 兑换装备',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                color: AppColors.hint,
                fontSize: 12,
              ),
            )
          else
            Column(
              children: data.inventory.map((g) {
                final bool equipped = equippedIds.contains(g.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              style: const TextStyle(
                                fontFamily: AppTheme.monoFontFamily,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              g.bonusStats.entries
                                  .map((e) =>
                                      '${e.key.toUpperCase()} +${e.value}')
                                  .join('  '),
                              style: const TextStyle(
                                fontFamily: AppTheme.monoFontFamily,
                                color: AppColors.alert,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        height: 34,
                        child: LCorpButton(
                          label: equipped ? 'UNEQUIP' : 'EQUIP',
                          height: 34,
                          enableScanline: false,
                          onPressed: () => _toggleEquip(
                            g,
                            equipped: equipped,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleEquip(EgoGear g, {required bool equipped}) async {
    final EgoShopService svc = ref.read(egoShopServiceProvider);
    final Agent agent = await ref
        .read(agentRepositoryProvider)
        .ensureDefaultUser();
    if (equipped) {
      await svc.unequip(agent.id, g.id);
    } else {
      await svc.equip(agent.id, g.id);
    }
    if (!mounted) return;
    setState(_refresh);
  }
}

class _AgentPanelData {
  _AgentPanelData({required this.agent, required this.inventory});
  final Agent agent;
  final List<EgoGear> inventory;

  static Future<_AgentPanelData> load({
    required AgentRepository agentRepo,
    required EgoRepository egoRepo,
  }) async {
    final Agent agent = await agentRepo.ensureDefaultUser();
    final List<EgoGear> inv = await egoRepo.getAll();
    return _AgentPanelData(agent: agent, inventory: inv);
  }
}
