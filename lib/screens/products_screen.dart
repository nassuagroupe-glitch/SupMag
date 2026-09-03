import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Sentinel [DropdownMenuItem] value that opens the free-text "new
/// category" field below the dropdown, instead of an existing category id.
const _newCategorySentinel = '__new_category__';

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
    final unit = TextEditingController(text: 'paquet');
    final barcode = TextEditingController();
    final newCategory = TextEditingController();
    final priceBuy = TextEditingController();
    final priceSell = TextEditingController();
    final initialStock = TextEditingController(text: '0');
    final threshold = TextEditingController(text: '50');
    final location = TextEditingController();
    final weightKg = TextEditingController();
    final unitsPerPack = TextEditingController();
    final packPrice = TextEditingController();
    final unitsPerCarton = TextEditingController();
    final cartonPrice = TextEditingController();
    var tva = 0.0;
    var vrac = false;

    final categories = state.productCategories;
    String? selectedCategory = categories.isNotEmpty ? categories.first : _newCategorySentinel;
    String? selectedSupplierId;
    var selectedStoreId = state.stores.any((s) => s.id == state.currentStoreId) ? state.currentStoreId : state.stores.first.id;
    Uint8List? photoBytes;
    String photoExt = 'jpg';
    String? photoName;

    Future<void> pickPhoto(StateSetter setDialogState) async {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dotIndex = file.name.lastIndexOf('.');
      setDialogState(() {
        photoBytes = bytes;
        photoExt = dotIndex == -1 ? 'jpg' : file.name.substring(dotIndex + 1).toLowerCase();
        photoName = file.name;
      });
    }

    Future<void> scanBarcode(BuildContext context, StateSetter setDialogState) async {
      if (defaultTargetPlatform != TargetPlatform.android) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Le scan par webcam n'est pas disponible sur cette version Windows. "
            "Utilisez un lecteur USB (le code se saisit directement dans le champ) ou saisissez-le depuis l'app mobile SupMag.",
          ),
        ));
        return;
      }
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Scanner un code-barres')),
            body: MobileScanner(
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                final value = capture.barcodes.first.rawValue;
                if (value != null) Navigator.of(context).pop(value);
              },
            ),
          ),
        ),
      );
      if (code != null) setDialogState(() => barcode.text = code);
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Nouveau produit'),
          content: SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nom du produit'),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcode,
                          decoration: const InputDecoration(labelText: 'Code-barres (scanner USB ou saisie)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Scanner avec la caméra',
                        onPressed: () => scanBarcode(context, setDialogState),
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      "Astuce : cliquez dans le champ code-barres puis scannez avec un lecteur USB — le code s'y saisit tout seul. "
                      "Ou utilisez le bouton caméra (Android) pour scanner. Laissez vide pour générer un code interne.",
                      style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                    ),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      OutlinedButton.icon(
                        onPressed: () => pickPhoto(setDialogState),
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Choisir un fichier'),
                      ),
                      const SizedBox(width: 10),
                      if (photoBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(photoBytes!, width: 32, height: 32, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(child: Text(photoName ?? 'Aucun fichier choisi', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.neutral700))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(labelText: 'Catégorie'),
                          isExpanded: true,
                          items: [
                            for (final c in categories) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)),
                            const DropdownMenuItem(value: _newCategorySentinel, child: Text('+ Nouvelle catégorie…')),
                          ],
                          onChanged: (v) => setDialogState(() => selectedCategory = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'Unité'))),
                    ]),
                    if (selectedCategory == _newCategorySentinel) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: newCategory,
                        decoration: const InputDecoration(labelText: 'Nom de la nouvelle catégorie'),
                        validator: (v) => selectedCategory == _newCategorySentinel && (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: selectedSupplierId,
                          decoration: const InputDecoration(labelText: 'Fournisseur'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Aucun')),
                            for (final s in state.suppliers) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setDialogState(() => selectedSupplierId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStoreId,
                          decoration: const InputDecoration(labelText: 'Dépôt'),
                          isExpanded: true,
                          items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))],
                          onChanged: (v) => setDialogState(() => selectedStoreId = v ?? selectedStoreId),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: priceSell, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix vente au détail (FCFA)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: priceBuy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix achat (FCFA)'))),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: initialStock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock initial'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: threshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seuil minimum'))),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Emplacement en magasin (ex: Allée 3, Étagère B)')),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: weightKg, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poids (kg, optionnel)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: unitsPerPack, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unités par paquet (optionnel)'))),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: packPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix du paquet (FCFA)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: unitsPerCarton, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unités par carton (optionnel)'))),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(controller: cartonPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix du carton (FCFA)')),
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
                final id = 'p${DateTime.now().microsecondsSinceEpoch}';
                var photoUrl = '';
                if (photoBytes != null) {
                  try {
                    photoUrl = await state.uploadProductPhoto(id, photoBytes!, extension: photoExt);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec de l'envoi de la photo : $e")));
                    }
                  }
                }
                final category = selectedCategory == _newCategorySentinel ? newCategory.text.trim() : (selectedCategory ?? '');
                final p = Product(
                  id: id,
                  name: name.text,
                  category: category.isEmpty ? 'Autres' : category,
                  unit: unit.text,
                  barcode: barcode.text.isEmpty ? '—' : barcode.text,
                  priceBuy: int.tryParse(priceBuy.text) ?? 0,
                  priceSell: int.tryParse(priceSell.text) ?? 0,
                  tva: tva,
                  vrac: vrac,
                  threshold: int.tryParse(threshold.text) ?? 50,
                  supplierId: selectedSupplierId ?? '',
                  location: location.text.trim(),
                  weightKg: double.tryParse(weightKg.text.replaceAll(',', '.')),
                  unitsPerPack: int.tryParse(unitsPerPack.text),
                  packPrice: int.tryParse(packPrice.text),
                  unitsPerCarton: int.tryParse(unitsPerCarton.text),
                  cartonPrice: int.tryParse(cartonPrice.text),
                  photoUrl: photoUrl,
                );
                await state.addProduct(p, initialStoreId: selectedStoreId, initialStock: double.tryParse(initialStock.text) ?? 0);
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
