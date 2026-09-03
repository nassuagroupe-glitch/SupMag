import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Store/warehouse directory — one card per point of vente with its live
/// stock health, so Direction can see which depot needs attention without
/// switching the active store first.
class DepotsScreen extends StatelessWidget {
  const DepotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Réseau'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Dépôts & magasins')),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final s in state.stores)
                SizedBox(
                  width: 300,
                  child: _DepotCard(state: state, storeId: s.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepotCard extends StatelessWidget {
  const _DepotCard({required this.state, required this.storeId});
  final AppState state;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    final s = state.store(storeId);
    final alerts = state.lowStockAlerts.where((a) => a.store.id == storeId).toList();
    final ruptures = alerts.where((a) => a.rupture).length;
    final sousSeuil = alerts.length - ruptures;
    final refs = state.products.where((p) => state.stockOf(p.id, storeId) > 0).length;
    final active = state.currentStoreId == storeId;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(s.city, style: const TextStyle(fontSize: 13, color: AppColors.neutral700)),
                  ],
                ),
              ),
              if (active) const StatusTag('Actif', variant: TagVariant.accent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Réfs en stock', value: '$refs'),
              _Stat(label: 'Ruptures', value: '$ruptures', color: ruptures > 0 ? AppColors.accent2_700 : null),
              _Stat(label: 'Sous seuil', value: '$sousSeuil'),
            ],
          ),
          const SizedBox(height: 12),
          if (!active)
            AppButton(
              label: 'Définir comme magasin actif',
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => state.setStore(storeId),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'Source Serif 4', fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
      ],
    );
  }
}
