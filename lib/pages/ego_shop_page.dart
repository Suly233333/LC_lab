import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/ego_gear.dart';
import '../services/ego_shop_service.dart';
import '../state/app_providers.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';

/// EGO 装备商店页。
///
/// 列出装备目录；已拥有项标记 OWNED，否则展示 PE Box 价格按钮，
/// 余额不足按钮置灰。
class EgoShopPage extends ConsumerStatefulWidget {
  const EgoShopPage({super.key});

  @override
  ConsumerState<EgoShopPage> createState() => _EgoShopPageState();
}

class _EgoShopPageState extends ConsumerState<EgoShopPage> {
  late Future<List<EgoGear>> _catalog;
  late Future<Set<String>> _owned;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final EgoShopService svc = ref.read(egoShopServiceProvider);
    _catalog = svc.loadCatalog();
    _owned = svc.ownedIds();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<int> balanceAsync = ref.watch(peBoxBalanceProvider);
    final int balance = balanceAsync.maybeWhen(
      data: (v) => v,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('EGO SHOP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '$balance PE',
                style: const TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: FutureBuilder<List<EgoGear>>(
              future: _catalog,
              builder: (_, catSnap) {
                if (!catSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }
                return FutureBuilder<Set<String>>(
                  future: _owned,
                  builder: (_, ownedSnap) {
                    final Set<String> owned =
                        ownedSnap.data ?? const <String>{};
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: catSnap.data!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final EgoGear g = catSnap.data![i];
                        return _EgoCard(
                          gear: g,
                          owned: owned.contains(g.id),
                          balance: balance,
                          onPurchase: () => _purchase(g),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(EgoGear g) async {
    final bool ok =
        await ref.read(egoShopServiceProvider).purchase(g);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('// PURCHASE REFUSED')),
      );
      return;
    }
    setState(_refresh);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('// ACQUIRED ${g.name}')),
    );
  }
}

class _EgoCard extends StatelessWidget {
  const _EgoCard({
    required this.gear,
    required this.owned,
    required this.balance,
    required this.onPurchase,
  });

  final EgoGear gear;
  final bool owned;
  final int balance;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final bool affordable = balance >= gear.cost;
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
                  gear.name,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (owned)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  color: AppColors.alert,
                  child: const Text(
                    'OWNED',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: AppColors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            gear.id,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.hint,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gear.description,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: gear.bonusStats.entries
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.alert, width: 1),
                      ),
                      child: Text(
                        '${e.key.toUpperCase()} +${e.value}',
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          color: AppColors.alert,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: LCorpButton(
              label: owned
                  ? 'IN INVENTORY'
                  : (affordable
                      ? 'PURCHASE  ${gear.cost} PE'
                      : 'INSUFFICIENT  ${gear.cost} PE'),
              height: 38,
              enableScanline: !owned && affordable,
              onPressed:
                  (owned || !affordable) ? null : onPurchase,
            ),
          ),
        ],
      ),
    );
  }
}
