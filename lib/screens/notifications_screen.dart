import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class _Notice {
  final String kicker;
  final Color kickerColor;
  final String title;
  final String meta;
  final IconData icon;
  const _Notice({required this.kicker, required this.kickerColor, required this.title, required this.meta, required this.icon});
}

/// Unified feed of everything else in the app already flags as needing
/// attention (stock alerts, transfers, purchase orders, receptions) — no
/// separate notifications store, just one place that reads all of them.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notices = <_Notice>[
      for (final a in state.lowStockAlerts)
        _Notice(
          kicker: a.rupture ? 'Rupture' : 'Sous seuil',
          kickerColor: AppColors.accent2_700,
          icon: Icons.inventory_2_outlined,
          title: '${a.product.name} — ${a.store.name}',
          meta: '${a.qty.toStringAsFixed(a.qty == a.qty.roundToDouble() ? 0 : 1)} ${a.product.unit} · seuil ${a.product.threshold}',
        ),
      for (final t in state.transfers.where((t) => t.status == TransferStatus.aValider))
        _Notice(
          kicker: 'Transfert',
          kickerColor: AppColors.accent700,
          icon: Icons.compare_arrows_outlined,
          title: '${t.ref} en attente de validation',
          meta: '${state.store(t.originStoreId).name} → ${state.store(t.destStoreId).name} · ${t.qty.round()} ${state.product(t.productId).unit}',
        ),
      for (final po in state.purchaseOrders.where((p) => p.status != 'Confirmée'))
        _Notice(
          kicker: 'Fournisseur',
          kickerColor: AppColors.accent700,
          icon: Icons.handshake_outlined,
          title: '${po.ref} — ${state.supplier(po.supplierId).name}',
          meta: 'Statut : ${po.status}',
        ),
      if (state.currentReception != null && state.currentReception!.status == 'Écart')
        _Notice(
          kicker: 'Réception',
          kickerColor: AppColors.accent2_700,
          icon: Icons.local_shipping_outlined,
          title: '${state.currentReception!.ref} avec écart',
          meta: '${state.supplier(state.currentReception!.supplierId).name} · ${state.currentStore.name}',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Activité'),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(children: [
              const ScreenTitle('Notifications'),
              const SizedBox(width: 12),
              if (notices.isNotEmpty) StatusTag('${notices.length}', variant: TagVariant.accent2),
            ]),
          ),
          if (notices.isEmpty)
            const Text('Rien à signaler pour le moment — tout est sous contrôle.', style: TextStyle(color: AppColors.neutral600, fontStyle: FontStyle.italic))
          else
            for (final n in notices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(n.icon, size: 20, color: n.kickerColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.kicker, style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: n.kickerColor)),
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(n.meta, style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
