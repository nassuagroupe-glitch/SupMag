import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const _categories = ['Loyer', 'Électricité', 'Transport', 'Salaires', 'Entretien', 'Autre'];

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sorted = [...state.expenses]..sort((a, b) => b.date.compareTo(a.date));
    final total = state.expenses.fold<int>(0, (a, e) => a + e.amount);
    final thisMonth = state.expenses.where((e) => e.date.year == DateTime.now().year && e.date.month == DateTime.now().month).fold<int>(0, (a, e) => a + e.amount);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Comptabilité'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Dépenses')),
          Wrap(spacing: 24, runSpacing: 12, children: [
            _Kpi(label: 'Total enregistré', value: '${fmtFcfa(total)} FCFA'),
            _Kpi(label: 'Ce mois-ci', value: '${fmtFcfa(thisMonth)} FCFA'),
          ]),
          const SizedBox(height: 18),
          AppButton(label: 'Ajouter une dépense', onPressed: () => _openAddDialog(context, state)),
          const SizedBox(height: 16),
          HScrollTable(
            minWidth: 680,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Magasin')),
                DataColumn(label: Text('Libellé')),
                DataColumn(label: Text('Catégorie')),
                DataColumn(label: Text('Montant'), numeric: true),
              ],
              rows: [
                for (final e in sorted)
                  DataRow(cells: [
                    DataCell(Text('${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}')),
                    DataCell(Text(state.store(e.storeId).name)),
                    DataCell(Text(e.label)),
                    DataCell(StatusTag(e.category, variant: TagVariant.neutral)),
                    DataCell(Text(fmtFcfa(e.amount))),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context, AppState state) async {
    final label = TextEditingController();
    final amount = TextEditingController();
    var storeId = state.currentStoreId;
    var category = _categories.first;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Ajouter une dépense'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: label, decoration: const InputDecoration(labelText: 'Libellé')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: storeId,
                  decoration: const InputDecoration(labelText: 'Magasin'),
                  items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name))],
                  onChanged: (v) => setDialogState(() => storeId = v ?? storeId),
                ),
                const SizedBox(height: 10),
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant (FCFA)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final amt = int.tryParse(amount.text.trim()) ?? 0;
                if (label.text.trim().isEmpty || amt <= 0) return;
                await state.addExpense(storeId: storeId, label: label.text.trim(), category: category, amount: amt);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      }),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 1.2, color: AppColors.neutral600)),
        Text(value, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 24, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
