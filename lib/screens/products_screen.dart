import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var products = state.products;
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q)).toList();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Référentiel central'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 18), child: ScreenTitle('Produits & prix')),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 260, child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'Rechercher une référence…'))),
              AppButton(label: 'Nouveau produit', onPressed: () => _openNewProductDialog(context, state)),
              AppButton(
                label: 'Appliquer un prix à tous les magasins',
                variant: AppButtonVariant.secondary,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les prix SupMag sont déjà uniformes sur les 10 magasins.')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HScrollTable(
            minWidth: 940,
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Produit')),
                DataColumn(label: Text('Code-barres')),
                DataColumn(label: Text('Catégorie')),
                DataColumn(label: Text('Unité')),
                DataColumn(label: Text('P. achat'), numeric: true),
                DataColumn(label: Text('P. vente'), numeric: true),
                DataColumn(label: Text('Marge'), numeric: true),
                DataColumn(label: Text('TVA')),
                DataColumn(label: Text('Prix local')),
              ],
              rows: [
                for (final p in products)
                  DataRow(cells: [
                    DataCell(Text(p.name)),
                    DataCell(Text(p.barcode)),
                    DataCell(Text(p.category)),
                    DataCell(Text(p.unit)),
                    DataCell(Text(fmtFcfa(p.priceBuy)), onTap: () => _editPrice(context, state, p, buy: true)),
                    DataCell(Text(fmtFcfa(p.priceSell)), onTap: () => _editPrice(context, state, p, buy: false)),
                    DataCell(Text('${p.marginPct.toStringAsFixed(1)} %')),
                    DataCell(Text(p.tva > 0 ? '18 %' : 'Exonéré')),
                    DataCell(p.vrac ? const StatusTag('Prix marché', variant: TagVariant.outline) : const StatusTag('Uniforme', variant: TagVariant.neutral)),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPrice(BuildContext context, AppState state, Product p, {required bool buy}) async {
    final ctrl = TextEditingController(text: (buy ? p.priceBuy : p.priceSell).toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(buy ? 'Prix d\'achat — ${p.name}' : 'Prix de vente — ${p.name}'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (result != null) {
      await state.updateProductPrice(p.id, priceBuy: buy ? result : null, priceSell: buy ? null : result);
    }
  }

  Future<void> _openNewProductDialog(BuildContext context, AppState state) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final category = TextEditingController(text: 'Épicerie');
    final unit = TextEditingController(text: 'paquet');
    final barcode = TextEditingController();
    final priceBuy = TextEditingController();
    final priceSell = TextEditingController();
    final threshold = TextEditingController(text: '50');
    var tva = 0.0;
    var vrac = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Nouveau produit'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nom'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
                    const SizedBox(height: 8),
                    TextFormField(controller: category, decoration: const InputDecoration(labelText: 'Catégorie')),
                    const SizedBox(height: 8),
                    TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'Unité')),
                    const SizedBox(height: 8),
                    TextFormField(controller: barcode, decoration: const InputDecoration(labelText: 'Code-barres')),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: priceBuy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'P. achat'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: priceSell, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'P. vente'))),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(controller: threshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seuil d\'alerte')),
                    CheckboxListTile(
                      value: tva > 0,
                      onChanged: (v) => setDialogState(() => tva = (v ?? false) ? 0.18 : 0.0),
                      title: const Text('Soumis à la TVA 18 %'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: vrac,
                      onChanged: (v) => setDialogState(() => vrac = v ?? false),
                      title: const Text('Vendu en vrac (au kg)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final p = Product(
                  id: 'p${DateTime.now().microsecondsSinceEpoch}',
                  name: name.text,
                  category: category.text,
                  unit: unit.text,
                  barcode: barcode.text.isEmpty ? '—' : barcode.text,
                  priceBuy: int.tryParse(priceBuy.text) ?? 0,
                  priceSell: int.tryParse(priceSell.text) ?? 0,
                  tva: tva,
                  vrac: vrac,
                  threshold: int.tryParse(threshold.text) ?? 50,
                );
                await state.addProduct(p);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      }),
    );
  }
}
