import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Product catalogue grouped by category — a read view derived from
/// [Product.category]; there is no separate categories collection, this
/// screen just aggregates the field products already carry.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final byCategory = <String, List<dynamic>>{};
    for (final p in state.products) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }
    final categories = byCategory.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Catalogue'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Catégories')),
          HScrollTable(
            minWidth: 640,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Catégorie')),
                DataColumn(label: Text('Produits'), numeric: true),
                DataColumn(label: Text('Valeur de stock'), numeric: true),
                DataColumn(label: Text('Alertes'), numeric: true),
              ],
              rows: [
                for (final cat in categories)
                  DataRow(cells: [
                    DataCell(Text(cat)),
                    DataCell(Text('${byCategory[cat]!.length}')),
                    DataCell(Text(fmtFcfa(_stockValue(state, cat)))),
                    DataCell(Text('${state.lowStockAlerts.where((a) => a.product.category == cat).length}')),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _stockValue(AppState state, String category) {
    double v = 0;
    for (final p in state.products.where((p) => p.category == category)) {
      v += state.totalStockOf(p.id) * p.priceSell;
    }
    return v;
  }
}
