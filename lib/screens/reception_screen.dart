import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ReceptionScreen extends StatelessWidget {
  const ReceptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reception = state.currentReception;

    if (reception == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text('Aucune réception en cours.', style: TextStyle(color: AppColors.neutral600)),
      );
    }

    final supplier = state.supplier(reception.supplierId);
    final store = state.store(reception.storeId);
    final lines = state.currentReceptionLines;
    final totalRecu = lines.fold<int>(0, (a, l) => a + l.amount);
    final ecartTotal = lines.fold<int>(0, (a, l) => a + (l.gap * l.buyPrice).round());

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionKicker('Magasinier · ${store.name}'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Réception de marchandises')),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 780;
            final form = _ReceptionForm(supplierName: supplier.name, storeName: store.name, ref: reception.ref, ecartTotal: ecartTotal);
            final table = _LinesTable(state: state, ref: reception.ref, supplierName: supplier.name, totalRecu: totalRecu, ecartTotal: ecartTotal);
            if (narrow) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [form, const SizedBox(height: 24), table]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: form),
                const SizedBox(width: 40),
                Expanded(child: table),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ReceptionForm extends StatelessWidget {
  const _ReceptionForm({required this.supplierName, required this.storeName, required this.ref, required this.ecartTotal});
  final String supplierName;
  final String storeName;
  final String ref;
  final int ecartTotal;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(label: 'Fournisseur', child: TextFormField(initialValue: supplierName, readOnly: true, decoration: const InputDecoration())),
        const SizedBox(height: 12),
        LabeledField(label: 'N° bon de livraison', child: TextFormField(initialValue: ref, readOnly: true, decoration: const InputDecoration())),
        const SizedBox(height: 12),
        LabeledField(label: 'Date de réception', child: TextFormField(initialValue: '02/09/2026', decoration: const InputDecoration())),
        const SizedBox(height: 12),
        LabeledField(label: 'Magasin destinataire', child: TextFormField(initialValue: storeName, readOnly: true, decoration: const InputDecoration())),
        const SizedBox(height: 12),
        const LabeledField(label: 'Scanner un article', child: TextField(decoration: InputDecoration(hintText: 'Douchette…'))),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          AppButton(label: 'Valider la réception', onPressed: state.validateReception),
          AppButton(label: 'Brouillon', variant: AppButtonVariant.ghost, onPressed: () {}),
        ]),
        const SizedBox(height: 12),
        Text.rich(TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
          children: [
            const TextSpan(text: 'Écart total : '),
            TextSpan(
              text: '${ecartTotal < 0 ? '−' : ''}${fmtFcfa(ecartTotal.abs())} FCFA',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent2_700),
            ),
            const TextSpan(text: ' · une réserve sera générée sur le BL si négatif.'),
          ],
        )),
      ],
    );
  }
}

class _LinesTable extends StatelessWidget {
  const _LinesTable({required this.state, required this.ref, required this.supplierName, required this.totalRecu, required this.ecartTotal});
  final AppState state;
  final String ref;
  final String supplierName;
  final int totalRecu;
  final int ecartTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lignes du bon — $ref · $supplierName', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        HScrollTable(
          minWidth: 820,
          child: DataTable(
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Produit')),
              DataColumn(label: Text('Lot')),
              DataColumn(label: Text('Péremption')),
              DataColumn(label: Text('Attendu'), numeric: true),
              DataColumn(label: Text('Reçu'), numeric: true),
              DataColumn(label: Text('Écart'), numeric: true),
              DataColumn(label: Text('P. achat'), numeric: true),
              DataColumn(label: Text('Montant'), numeric: true),
            ],
            rows: [
              for (final l in state.currentReceptionLines)
                DataRow(cells: [
                  DataCell(Text(state.product(l.productId).name)),
                  DataCell(Text(l.lot)),
                  DataCell(Text(l.expiry ?? '—')),
                  DataCell(Text('${l.expectedQty.round()}')),
                  DataCell(SizedBox(
                    width: 64,
                    child: TextFormField(
                      key: ValueKey('${l.id}-${l.receivedQty}'),
                      initialValue: '${l.receivedQty.round()}',
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                      onFieldSubmitted: (v) => state.setReceivedQty(l.productId, double.tryParse(v) ?? l.receivedQty),
                    ),
                  )),
                  DataCell(Text(
                    l.gap == 0 ? '0' : (l.gap > 0 ? '+${l.gap.round()}' : '${l.gap.round()}'),
                    style: TextStyle(color: l.gap == 0 ? AppColors.text : AppColors.accent2_700),
                  )),
                  DataCell(Text(fmtFcfa(l.buyPrice))),
                  DataCell(Text(fmtFcfa(l.amount))),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 40,
          runSpacing: 12,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL REÇU', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600)),
              Text('${fmtFcfa(totalRecu)} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 26, fontWeight: FontWeight.w700)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RÉSERVE ÉCART', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600)),
              Text('${fmtFcfa(ecartTotal.abs())} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.accent2_700)),
            ]),
          ],
        ),
      ],
    );
  }
}
