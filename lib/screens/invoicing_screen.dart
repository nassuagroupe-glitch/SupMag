import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Receipts issued by the Caisse, presented as an invoice register. SupMag
/// doesn't talk to an external accounting/e-invoicing service yet — this is
/// the in-app record until one is connected.
class InvoicingScreen extends StatelessWidget {
  const InvoicingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tickets = [...state.recentTickets]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final total = tickets.fold<int>(0, (a, t) => a + t.totalTtc);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Comptabilité'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Facturation')),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const Text(
              "Registre des tickets de caisse des 30 derniers jours, en attendant une intégration avec un logiciel de facturation externe.",
              style: TextStyle(color: AppColors.neutral700),
            ),
          ),
          const SizedBox(height: 16),
          Text('${fmtFcfa(total)} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 26, fontWeight: FontWeight.w700)),
          const Text('Chiffre d\'affaires facturé · 30 jours', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
          const SizedBox(height: 18),
          HScrollTable(
            minWidth: 680,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('N° ticket')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Magasin')),
                DataColumn(label: Text('Paiement')),
                DataColumn(label: Text('Montant TTC'), numeric: true),
              ],
              rows: [
                for (final t in tickets.take(200))
                  DataRow(cells: [
                    DataCell(Text('#${t.ticketNo}')),
                    DataCell(Text('${t.createdAt.day.toString().padLeft(2, '0')}/${t.createdAt.month.toString().padLeft(2, '0')} ${t.createdAt.hour.toString().padLeft(2, '0')}h${t.createdAt.minute.toString().padLeft(2, '0')}')),
                    DataCell(Text(state.store(t.storeId).name)),
                    DataCell(Text(t.payMethod)),
                    DataCell(Text(fmtFcfa(t.totalTtc))),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
