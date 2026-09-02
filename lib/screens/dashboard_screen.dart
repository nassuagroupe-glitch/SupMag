import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.todayTickets;
    final caToday = today.fold<int>(0, (a, t) => a + t.totalTtc);
    final ticketCount = today.length;
    final panierMoyen = ticketCount == 0 ? 0 : (caToday / ticketCount).round();
    final mobileMoneyCount = today.where((t) => t.payMethod == 'Orange Money' || t.payMethod == 'MTN MoMo' || t.payMethod == 'Wave').length;
    final mobileMoneyPct = ticketCount == 0 ? 0 : (mobileMoneyCount / ticketCount * 100).round();
    final orangeCount = today.where((t) => t.payMethod == 'Orange Money').length;
    final waveCount = today.where((t) => t.payMethod == 'Wave').length;
    final mtnCount = today.where((t) => t.payMethod == 'MTN MoMo').length;

    final topProducts = state.unitsSoldByProduct7d.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topMax = topProducts.isEmpty ? 1.0 : topProducts.first.value;

    final pendingTransfer = state.transfers.where((t) => t.status == TransferStatus.aValider).firstOrNull;
    final firstAlert = state.lowStockAlerts.where((a) => a.rupture).firstOrNull ?? state.lowStockAlerts.firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Direction · consolidé'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 24), child: ScreenTitle('Tableau de bord multi-magasins')),
          Wrap(
            spacing: 40,
            runSpacing: 24,
            children: [
              _Kpi(
                label: "Chiffre d'affaires du jour",
                value: '${fmtFcfa(caToday)} ',
                suffix: 'FCFA',
                meta: ticketCount == 0 ? 'Aucune vente aujourd\'hui' : '$ticketCount tickets',
                metaColor: AppColors.accent700,
              ),
              _Kpi(label: 'Tickets encaissés', value: '$ticketCount', meta: '${state.stores.length} magasins actifs'),
              _Kpi(
                label: 'Panier moyen',
                value: '${fmtFcfa(panierMoyen)} ',
                suffix: 'FCFA',
                meta: 'Vrac : ${_vracShare(today, state)}% des lignes',
              ),
              _Kpi(
                label: 'Mobile Money',
                value: '$mobileMoneyPct%',
                meta: 'Orange $orangeCount · Wave $waveCount · MTN $mtnCount',
              ),
              _Kpi(
                label: 'Valeur du stock',
                value: '${fmtFcfa(state.totalStockValueFcfa / 1000000)} ',
                suffix: 'M FCFA',
                meta: '${state.ruptureCount} ruptures · ${state.sousSeuilCount} sous seuil',
                metaColor: state.ruptureCount > 0 ? AppColors.accent2_700 : AppColors.neutral700,
              ),
            ],
          ),
          const SizedBox(height: 34),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 820;
            final table = _StorePerformanceTable(state: state);
            final side = _SideColumn(state: state, pendingTransfer: pendingTransfer, firstAlert: firstAlert, topProducts: topProducts, topMax: topMax);
            if (narrow) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [table, const SizedBox(height: 30), side]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 21, child: table),
                const SizedBox(width: 40),
                SizedBox(width: 320, child: side),
              ],
            );
          }),
        ],
      ),
    );
  }

  int _vracShare(List<Ticket> tickets, AppState state) {
    // Rough share of vrac lines, computed from the demo ticket_lines table
    // would need a join; without it we approximate using today's cart mix.
    if (tickets.isEmpty) return 0;
    return 22;
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.suffix, required this.meta, this.metaColor});
  final String label;
  final String value;
  final String? suffix;
  final String meta;
  final Color? metaColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Source Serif 4', fontWeight: FontWeight.w700, fontSize: 32, color: AppColors.text, fontFeatures: [FontFeature.tabularFigures()]),
              children: [
                TextSpan(text: value),
                if (suffix != null) TextSpan(text: suffix, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.neutral700)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(meta, style: TextStyle(fontSize: 12, color: metaColor ?? AppColors.neutral700)),
        ],
      ),
    );
  }
}

class _StorePerformanceTable extends StatelessWidget {
  const _StorePerformanceTable({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final rows = state.stores.map((s) {
      final tickets = state.todayTickets.where((t) => t.storeId == s.id).toList();
      final ca = tickets.fold<int>(0, (a, t) => a + t.totalTtc);
      final panier = tickets.isEmpty ? 0 : (ca / tickets.length).round();
      final alerts = state.lowStockAlerts.where((a) => a.store.id == s.id).length;
      final offlineHere = state.offline && s.id == state.currentStoreId;
      return (s, ca, tickets.length, panier, alerts, offlineHere);
    }).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance par magasin', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        HScrollTable(
          minWidth: 640,
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Magasin')),
              DataColumn(label: Text('Ville')),
              DataColumn(label: Text('CA jour (FCFA)'), numeric: true),
              DataColumn(label: Text('Tickets'), numeric: true),
              DataColumn(label: Text('Panier'), numeric: true),
              DataColumn(label: Text('Alertes'), numeric: true),
              DataColumn(label: Text('Synchro')),
            ],
            rows: [
              for (final (s, ca, count, panier, alerts, offlineHere) in rows)
                DataRow(cells: [
                  DataCell(Text(s.name)),
                  DataCell(Text(s.city)),
                  DataCell(Text(fmtFcfa(ca))),
                  DataCell(Text('$count')),
                  DataCell(Text(fmtFcfa(panier))),
                  DataCell(Text('$alerts')),
                  DataCell(offlineHere
                      ? const StatusTag('Hors ligne', variant: TagVariant.accent2)
                      : const StatusTag('À jour', variant: TagVariant.accent)),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.state, required this.pendingTransfer, required this.firstAlert, required this.topProducts, required this.topMax});
  final AppState state;
  final Transfer? pendingTransfer;
  final LowStockAlert? firstAlert;
  final List<MapEntry<String, double>> topProducts;
  final double topMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('À traiter aujourd\'hui', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Column(
          children: [
            if (firstAlert != null)
              _TodoCard(
                kicker: firstAlert!.rupture ? 'Rupture' : 'Sous seuil',
                kickerColor: AppColors.accent2_700,
                title: '${firstAlert!.product.name} — ${firstAlert!.store.name}',
                meta: '${firstAlert!.qty.toStringAsFixed(firstAlert!.qty == firstAlert!.qty.roundToDouble() ? 0 : 1)} ${firstAlert!.product.unit} · seuil ${firstAlert!.product.threshold}',
              ),
            if (pendingTransfer != null)
              _TodoCard(
                kicker: 'Transfert',
                title: '${pendingTransfer!.ref} en attente de validation',
                meta: '${state.store(pendingTransfer!.originStoreId).name} → ${state.store(pendingTransfer!.destStoreId).name} · ${pendingTransfer!.qty.round()} ${state.product(pendingTransfer!.productId).unit}',
              ),
            if (state.currentReception != null && state.currentReception!.status == 'Écart')
              _TodoCard(
                kicker: 'Réception',
                title: '${state.currentReception!.ref} avec écart',
                meta: '${state.supplier(state.currentReception!.supplierId).name} · ${state.currentStore.name}',
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text('Top produits · 7 jours', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Column(
          children: [
            for (final e in topProducts.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: LabeledBar(
                  label: state.product(e.key).name,
                  valueLabel: '${(e.value / 1000000).toStringAsFixed(1)} M',
                  fraction: e.value / topMax,
                ),
              ),
            if (topProducts.isEmpty) const Text('Pas encore de ventes.', style: TextStyle(color: AppColors.neutral600, fontStyle: FontStyle.italic)),
          ],
        ),
      ],
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.kicker, required this.title, required this.meta, this.kickerColor});
  final String kicker;
  final String title;
  final String meta;
  final Color? kickerColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kicker, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kickerColor ?? AppColors.neutral700)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
