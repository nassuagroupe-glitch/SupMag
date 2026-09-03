import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

/// Store manager's daily view: today's numbers for their store, stock
/// alerts, and one-tap actions (ask for a transfer, close out the till).
class MobileManagerScreen extends StatelessWidget {
  const MobileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final store = state.currentStore;
    final tickets = state.todayTickets.where((t) => t.storeId == store.id).toList();
    final ca = tickets.fold<int>(0, (a, t) => a + t.totalTtc);
    final alerts = state.lowStockAlerts.where((a) => a.store.id == store.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gérant · ${store.name}',
                      style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Ma journée', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: state.currentStoreId,
                underline: const SizedBox.shrink(),
                items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name.split(' ').first))],
                onChanged: (v) => v == null ? null : state.setStore(v),
              ),
              IconButton(
                onPressed: state.logout,
                icon: const Icon(Icons.logout, size: 18),
                tooltip: 'Déconnexion',
                color: AppColors.neutral600,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('CA DU JOUR', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600)),
          Text('${fmtFcfa(ca)} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 30, fontWeight: FontWeight.w700)),
          Text('${tickets.length} tickets aujourd\'hui', style: const TextStyle(fontSize: 12, color: AppColors.accent700)),
          const SizedBox(height: 20),
          const Text('ALERTES', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600)),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            const Text('Aucune alerte de stock pour ce magasin.', style: TextStyle(fontSize: 13, color: AppColors.neutral700))
          else
            for (final a in alerts.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text.rich(TextSpan(
                  style: const TextStyle(fontSize: 13),
                  children: [
                    TextSpan(text: '${a.product.name} — '),
                    TextSpan(
                      text: a.rupture ? 'rupture' : 'sous seuil (${a.qty.round()})',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent2_700),
                    ),
                  ],
                )),
              ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Demander un transfert',
            expand: true,
            onPressed: alerts.isEmpty
                ? null
                : () async {
                    final alert = alerts.first;
                    final source = state.bestSourceStoreFor(alert.product.id, store.id);
                    if (source == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun autre magasin n\'a de stock disponible.')));
                      return;
                    }
                    await state.createTransfer(originStoreId: source, destStoreId: store.id, productId: alert.product.id, qty: alert.product.threshold.toDouble());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transfert demandé à ${state.store(source).name}.')),
                      );
                    }
                  },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Clôturer la caisse du soir',
            variant: AppButtonVariant.ghost,
            expand: true,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caisse clôturée pour la journée.'))),
          ),
          const SizedBox(height: 12),
          Text(
            state.offline ? 'Hors ligne — synchronisation en attente' : 'Synchronisé il y a 1 min',
            style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}
