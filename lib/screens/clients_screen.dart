import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Customer directory — built from the credit accounts, SupMag's only
/// customer record today (a walk-in buyer with no ardoise leaves no trace).
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var clients = state.creditAccounts;
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      clients = clients.where((c) => c.customerName.toLowerCase().contains(q)).toList();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Relation client'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Clients')),
          Row(children: [
            AppButton(label: 'Ajouter un client', onPressed: () => _openAddDialog(context, state)),
            const SizedBox(width: 8),
            Expanded(child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'Rechercher…'))),
          ]),
          const SizedBox(height: 16),
          HScrollTable(
            minWidth: 640,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Magasin')),
                DataColumn(label: Text('Solde ardoise'), numeric: true),
                DataColumn(label: Text('Plafond'), numeric: true),
                DataColumn(label: Text('Statut')),
              ],
              rows: [
                for (final c in clients)
                  DataRow(cells: [
                    DataCell(Text(c.customerName)),
                    DataCell(Text(state.store(c.storeId).name)),
                    DataCell(Text(fmtFcfa(c.balance))),
                    DataCell(Text(fmtFcfa(c.ceiling))),
                    DataCell(StatusTag(
                      c.balance == 0 ? 'Soldé' : (c.balance >= c.ceiling ? 'Plafond atteint' : 'En cours'),
                      variant: c.balance == 0 ? TagVariant.accent : (c.balance >= c.ceiling ? TagVariant.accent2 : TagVariant.outline),
                    )),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context, AppState state) async {
    final name = TextEditingController();
    var storeId = state.currentStoreId;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Ajouter un client'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom du client')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: storeId,
                  decoration: const InputDecoration(labelText: 'Magasin'),
                  items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name))],
                  onChanged: (v) => setDialogState(() => storeId = v ?? storeId),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await state.addClient(name: name.text.trim(), storeId: storeId);
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
