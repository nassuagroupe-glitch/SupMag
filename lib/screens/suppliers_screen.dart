import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Achats centralisés'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Fournisseurs & commandes')),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 780;
            final left = _OrdersColumn(state: state);
            final right = _SuppliersColumn(state: state);
            if (narrow) return Column(children: [left, const SizedBox(height: 24), right]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 40), SizedBox(width: 320, child: right)],
            );
          }),
        ],
      ),
    );
  }
}

class _OrdersColumn extends StatelessWidget {
  const _OrdersColumn({required this.state});
  final AppState state;

  TagVariant _variant(String status) => switch (status) {
        'Confirmée' => TagVariant.accent,
        'En attente' => TagVariant.outline,
        _ => TagVariant.accent2,
      };

  @override
  Widget build(BuildContext context) {
    final months = ['jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commandes en cours', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        HScrollTable(
          minWidth: 760,
          child: DataTable(
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Réf.')),
              DataColumn(label: Text('Fournisseur')),
              DataColumn(label: Text('Livraison prévue')),
              DataColumn(label: Text('Lignes'), numeric: true),
              DataColumn(label: Text('Montant'), numeric: true),
              DataColumn(label: Text('Paiement')),
              DataColumn(label: Text('Statut')),
            ],
            rows: [
              for (final po in state.purchaseOrders)
                DataRow(cells: [
                  DataCell(Text(po.ref)),
                  DataCell(Text(state.supplier(po.supplierId).name)),
                  DataCell(Text('${po.expectedDate.day.toString().padLeft(2, '0')} ${months[po.expectedDate.month - 1]}')),
                  DataCell(Text('${po.linesCount}')),
                  DataCell(Text(fmtFcfa(po.amount))),
                  DataCell(Text(po.paymentTerms)),
                  DataCell(StatusTag(po.status, variant: _variant(po.status))),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('Réapprovisionnement suggéré', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            state.lowStockAlerts.isEmpty
                ? "Aucune alerte de stock actuellement — pas de réapprovisionnement nécessaire."
                : "Calculé à partir de ${state.lowStockAlerts.length} alertes de stock en cours (${state.ruptureCount} ruptures, ${state.sousSeuilCount} sous seuil). Un bon de commande peut être généré par fournisseur en un clic.",
            style: const TextStyle(color: AppColors.neutral800),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          AppButton(
            label: 'Générer des bons de commande',
            onPressed: () async {
              await state.generateSuggestedPurchaseOrders();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bons de commande générés.')));
            },
          ),
          AppButton(
            label: 'Ajuster les seuils',
            variant: AppButtonVariant.ghost,
            onPressed: () => Provider.of<AppState>(context, listen: false).setDesktopScreen('stock'),
          ),
        ]),
      ],
    );
  }
}

class _SuppliersColumn extends StatelessWidget {
  const _SuppliersColumn({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in state.suppliers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.categoryLabel, style: const TextStyle(fontSize: 11, color: AppColors.neutral600, fontWeight: FontWeight.w600)),
                  Text(s.name, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 17, fontWeight: FontWeight.w600)),
                  Text(
                    'Délai moyen ${s.avgDelayDays} j · fiabilité ${s.reliabilityPct.round()} % · encours ${s.encours == 0 ? 'comptant' : '${fmtFcfa(s.encours)} FCFA'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text('${s.contactName} — ${s.phone}', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
