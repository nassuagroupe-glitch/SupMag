import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});
  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  String? origin;
  String? dest;
  String? productId;
  final qtyCtrl = TextEditingController(text: '60');

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    origin ??= state.stores.first.id;
    dest ??= state.stores[1].id;
    productId ??= state.products.first.id;

    final suggestion = state.lowStockAlerts.where((a) => a.rupture).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Logistique inter-magasins'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Transferts entre magasins')),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 780;
            final table = _TransfersTable(state: state);
            final form = _NewTransferForm(
              origin: origin!, dest: dest!, productId: productId!, qtyCtrl: qtyCtrl,
              onOrigin: (v) => setState(() => origin = v),
              onDest: (v) => setState(() => dest = v),
              onProduct: (v) => setState(() => productId = v),
              suggestion: suggestion,
            );
            if (narrow) return Column(children: [table, const SizedBox(height: 24), form]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: table), const SizedBox(width: 40), SizedBox(width: 300, child: form)],
            );
          }),
        ],
      ),
    );
  }
}

class _TransfersTable extends StatelessWidget {
  const _TransfersTable({required this.state});
  final AppState state;

  TagVariant _variantFor(TransferStatus s) => switch (s) {
        TransferStatus.aValider => TagVariant.accent2,
        TransferStatus.enRoute => TagVariant.accent,
        TransferStatus.recu => TagVariant.neutral,
        TransferStatus.ecart => TagVariant.outline,
      };

  @override
  Widget build(BuildContext context) {
    return HScrollTable(
      minWidth: 820,
      child: DataTable(
        columnSpacing: 18,
        columns: const [
          DataColumn(label: Text('Réf.')),
          DataColumn(label: Text('Origine')),
          DataColumn(label: Text('Destination')),
          DataColumn(label: Text('Contenu')),
          DataColumn(label: Text('Valeur'), numeric: true),
          DataColumn(label: Text('Transport')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final t in state.transfers)
            DataRow(cells: [
              DataCell(Text(t.ref)),
              DataCell(Text(state.store(t.originStoreId).name)),
              DataCell(Text(state.store(t.destStoreId).name)),
              DataCell(Text('${state.product(t.productId).name} ×${t.qty.round()}')),
              DataCell(Text(fmtFcfa(t.value))),
              DataCell(Text(t.transport)),
              DataCell(StatusTag(t.status.label, variant: _variantFor(t.status))),
              DataCell(t.status == TransferStatus.recu
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: () => state.advanceTransfer(t),
                      child: Text(t.status == TransferStatus.aValider ? 'Valider' : 'Marquer reçu', style: const TextStyle(fontSize: 12)),
                    )),
            ]),
        ],
      ),
    );
  }
}

class _NewTransferForm extends StatelessWidget {
  const _NewTransferForm({
    required this.origin,
    required this.dest,
    required this.productId,
    required this.qtyCtrl,
    required this.onOrigin,
    required this.onDest,
    required this.onProduct,
    required this.suggestion,
  });
  final String origin;
  final String dest;
  final String productId;
  final TextEditingController qtyCtrl;
  final ValueChanged<String?> onOrigin;
  final ValueChanged<String?> onDest;
  final ValueChanged<String?> onProduct;
  final LowStockAlert? suggestion;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nouveau transfert', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        LabeledField(
          label: 'Origine',
          child: DropdownButtonFormField<String>(
            initialValue: origin,
            isExpanded: true,
            items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))],
            onChanged: onOrigin,
          ),
        ),
        const SizedBox(height: 10),
        LabeledField(
          label: 'Destination',
          child: DropdownButtonFormField<String>(
            initialValue: dest,
            isExpanded: true,
            items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))],
            onChanged: onDest,
          ),
        ),
        const SizedBox(height: 10),
        LabeledField(
          label: 'Produit',
          child: DropdownButtonFormField<String>(
            initialValue: productId,
            isExpanded: true,
            items: [for (final p in state.products) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
            onChanged: onProduct,
          ),
        ),
        const SizedBox(height: 10),
        LabeledField(label: 'Quantité', child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number)),
        const SizedBox(height: 14),
        AppButton(
          label: 'Créer et demander validation',
          onPressed: () {
            if (origin == dest) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Origine et destination doivent différer.')));
              return;
            }
            final qty = double.tryParse(qtyCtrl.text) ?? 0;
            if (qty <= 0) return;
            state.createTransfer(originStoreId: origin, destStoreId: dest, productId: productId, qty: qty);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfert créé.')));
          },
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 12),
          Text(
            'Suggestion automatique : ${suggestion!.store.name} est en rupture sur ${suggestion!.product.name}.',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
          ),
        ],
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
