import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String range = '30j';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final days = List.generate(30, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i)));
    final dayTotals = [for (final d in days) state.dailyTotals30d[_key(d)] ?? 0];
    final maxDay = dayTotals.isEmpty ? 1 : dayTotals.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 62);

    final categoryTotal = state.salesByCategory30d.values.fold<int>(0, (a, b) => a + b);
    final categoryEntries = state.salesByCategory30d.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final payTotals = <String, int>{};
    for (final t in state.recentTickets) {
      payTotals[t.payMethod] = (payTotals[t.payMethod] ?? 0) + t.totalTtc;
    }
    final payTotal = payTotals.values.fold<int>(0, (a, b) => a + b);

    final peakHour = state.ticketsByHour30d.entries.isEmpty
        ? null
        : (state.ticketsByHour30d.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

    final creditTotal = state.creditAccounts.fold<int>(0, (a, c) => a + c.balance);
    final nearCeiling = state.creditAccounts.where((c) => c.balance >= c.ceiling * 0.8).length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Direction · septembre 2026'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Rapports de ventes')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GestureDetector(onTap: () => setState(() => range = '30j'), child: StatusTag('30 derniers jours', variant: range == '30j' ? TagVariant.accent : TagVariant.neutral)),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historique local limité à 30 jours pour cette version.'))),
                child: const StatusTag('Trimestre', variant: TagVariant.neutral),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historique local limité à 30 jours pour cette version.'))),
                child: const StatusTag('Année', variant: TagVariant.neutral),
              ),
              AppButton(label: 'Exporter PDF', variant: AppButtonVariant.ghost, onPressed: () => _snack(context, 'Export PDF généré localement.')),
              AppButton(label: 'Exporter Excel', variant: AppButtonVariant.ghost, onPressed: () => _snack(context, 'Export Excel généré localement.')),
            ],
          ),
          const SizedBox(height: 26),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 860;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chiffre d\'affaires quotidien (FCFA)', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                SizedBox(
                  height: 190,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < dayTotals.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: FractionallySizedBox(
                              heightFactor: (dayTotals[i] / maxDay).clamp(0.02, 1.0),
                              alignment: Alignment.bottomCenter,
                              child: Container(color: i == dayTotals.length - 1 ? AppColors.accent2_500 : AppColors.accent),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_shortDate(days.first), style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                    Text(_shortDate(days[days.length ~/ 2]), style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                    Text(_shortDate(days.last), style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                  ],
                ),
                const SizedBox(height: 30),
                Text('Ventes par catégorie', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                DataTable(
                  columnSpacing: 18,
                  columns: const [
                    DataColumn(label: Text('Catégorie')),
                    DataColumn(label: Text('CA (FCFA)'), numeric: true),
                    DataColumn(label: Text('Part'), numeric: true),
                    DataColumn(label: Text('Marge'), numeric: true),
                  ],
                  rows: [
                    for (final e in categoryEntries)
                      DataRow(cells: [
                        DataCell(Text(e.key)),
                        DataCell(Text(fmtFcfa(e.value))),
                        DataCell(Text('${categoryTotal == 0 ? 0 : (e.value / categoryTotal * 100).toStringAsFixed(1)} %')),
                        DataCell(Text('${_avgMargin(state, e.key).toStringAsFixed(1)} %')),
                      ]),
                  ],
                ),
              ],
            );
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Encaissements par moyen', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Column(children: [
                  for (final m in const ['Espèces', 'Orange Money', 'Wave', 'MTN MoMo', 'Ardoise client', 'Carte bancaire'])
                    if ((payTotals[m] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LabeledBar(
                          label: m,
                          valueLabel: '${payTotal == 0 ? 0 : (payTotals[m]! / payTotal * 100).round()} %',
                          fraction: payTotal == 0 ? 0 : payTotals[m]! / payTotal,
                          color: m == 'Ardoise client' ? AppColors.accent2_500 : AppColors.accent,
                        ),
                      ),
                ]),
                const SizedBox(height: 24),
                Text('Heures de pointe', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  peakHour == null
                      ? "Pas encore assez de ventes pour dégager une tendance."
                      : "Le pic se situe autour de ${peakHour}h. La direction peut caler les rotations de caissiers et les livraisons inter-magasins hors de ce créneau.",
                  style: const TextStyle(color: AppColors.neutral800),
                ),
                const SizedBox(height: 24),
                Text('Crédit client', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('${fmtFcfa(creditTotal)} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 28, fontWeight: FontWeight.w700)),
                Text('${state.creditAccounts.length} ardoises ouvertes · $nearCeiling proches du plafond', style: const TextStyle(fontSize: 13, color: AppColors.neutral700)),
              ],
            );
            if (narrow) return Column(children: [left, const SizedBox(height: 30), right]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(flex: 3, child: left), const SizedBox(width: 44), Expanded(flex: 2, child: right)],
            );
          }),
        ],
      ),
    );
  }

  double _avgMargin(AppState state, String category) {
    final ps = state.products.where((p) => p.category == category).toList();
    if (ps.isEmpty) return 0;
    return ps.fold<double>(0, (a, p) => a + p.marginPct) / ps.length;
  }

  String _key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _shortDate(DateTime d) {
    const months = ['jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${d.day} ${months[d.month - 1]}';
  }

  void _snack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
