import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Company-level overview: the group's identity and its network of points
/// of vente, as opposed to Dépôts' operational stock-health view.
class EstablishmentScreen extends StatelessWidget {
  const EstablishmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cities = state.stores.map((s) => s.city).toSet().length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Organisation'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Établissement')),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.lg),
                  child: const Text('S', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Source Serif 4')),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SupMag', style: TextStyle(fontFamily: 'Source Serif 4', fontSize: 20, fontWeight: FontWeight.w700)),
                      const Text('Gestion multi-magasins · Côte d\'Ivoire', style: TextStyle(color: AppColors.neutral700)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 16, runSpacing: 6, children: [
                        StatusTag('${state.stores.length} magasins', variant: TagVariant.outline),
                        StatusTag('$cities villes', variant: TagVariant.outline),
                        StatusTag('${state.users.length} utilisateurs', variant: TagVariant.outline),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Points de vente', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          HScrollTable(
            minWidth: 620,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Magasin')),
                DataColumn(label: Text('Ville')),
                DataColumn(label: Text('Responsable(s)')),
              ],
              rows: [
                for (final s in state.stores)
                  DataRow(cells: [
                    DataCell(Text(s.name)),
                    DataCell(Text(s.city)),
                    DataCell(Text(_managersFor(state, s.id))),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _managersFor(AppState state, String storeId) {
    final names = state.users.where((u) => u.storeId == storeId && (u.role.startsWith('Gérant'))).map((u) => u.name).toList();
    return names.isEmpty ? '—' : names.join(', ');
  }
}
