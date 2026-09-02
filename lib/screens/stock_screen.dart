import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';

const _displayStoreIds = ['yopougon', 'cocody', 'adjame', 'abobo', 'bouake'];

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final expiringSoon = state.currentReceptionLines.where((l) {
      if (l.expiry == null) return false;
      final parts = l.expiry!.split('/');
      if (parts.length != 2) return false;
      final expiryDate = DateTime(int.parse(parts[1]), int.parse(parts[0]) + 1);
      return expiryDate.difference(DateTime.now()).inDays < 30;
    }).length;

    var products = state.products;
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q)).toList();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Magasinier · consolidé 10 magasins'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 18), child: ScreenTitle('Stock & inventaire')),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(hintText: 'Produit, code-barres, catégorie…'),
                ),
              ),
              StatusTag('Sous seuil (${state.sousSeuilCount})', variant: TagVariant.accent2),
              StatusTag('Rupture (${state.ruptureCount})', variant: TagVariant.neutral),
              StatusTag('Péremption < 30 j ($expiringSoon)', variant: TagVariant.neutral),
              AppButton(label: 'Lancer un inventaire tournant', variant: AppButtonVariant.secondary, onPressed: () => _snack(context, 'Inventaire tournant démarré.')),
              AppButton(label: 'Exporter (CSV)', variant: AppButtonVariant.ghost, onPressed: () => _snack(context, 'Export CSV généré localement.')),
            ],
          ),
          const SizedBox(height: 18),
          HScrollTable(
            minWidth: 940,
            child: DataTable(
              columnSpacing: 18,
              columns: [
                const DataColumn(label: Text('Produit')),
                const DataColumn(label: Text('Unité')),
                for (final id in _displayStoreIds) DataColumn(label: Text(state.store(id).name.split(' ').first), numeric: true),
                const DataColumn(label: Text('Total'), numeric: true),
                const DataColumn(label: Text('Seuil'), numeric: true),
                const DataColumn(label: Text('État')),
              ],
              rows: [
                for (final p in products)
                  DataRow(cells: [
                    DataCell(Text(p.name)),
                    DataCell(Text(p.unit)),
                    for (final id in _displayStoreIds) DataCell(Text(_qtyLabel(state.stockOf(p.id, id)))),
                    DataCell(Text(_qtyLabel(state.totalStockOf(p.id)))),
                    DataCell(Text('${p.threshold}')),
                    DataCell(_stateTag(state, p)),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _qtyLabel(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  Widget _stateTag(AppState state, Product p) {
    final byStore = state.stockMatrix[p.id] ?? const {};
    final ruptureStore = byStore.entries.where((e) => e.value == 0).firstOrNullEntry;
    if (ruptureStore != null) return StatusTag('Rupture ${state.store(ruptureStore.key).name.split(' ').first}', variant: TagVariant.accent2);
    final lowStore = byStore.entries.where((e) => e.value <= p.threshold).firstOrNullEntry;
    if (lowStore != null) return StatusTag('Sous seuil ${state.store(lowStore.key).name.split(' ').first}', variant: TagVariant.outline);
    if (p.vrac) return const StatusTag('Périssable', variant: TagVariant.neutral);
    return const StatusTag('Normal', variant: TagVariant.accent);
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

extension _FirstEntry on Iterable<MapEntry<String, double>> {
  MapEntry<String, double>? get firstOrNullEntry => isEmpty ? null : first;
}
