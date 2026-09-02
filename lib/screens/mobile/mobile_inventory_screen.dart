import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

const _motifs = ['Casse / avarie', 'Vol suspecté', 'Erreur de saisie'];

/// Barcode-scan inventory count: step through the catalog one product at a
/// time, compare counted quantity to the theoretical stock, and require a
/// reason when there's a gap.
class MobileInventoryScreen extends StatefulWidget {
  const MobileInventoryScreen({super.key});
  @override
  State<MobileInventoryScreen> createState() => _MobileInventoryScreenState();
}

class _MobileInventoryScreenState extends State<MobileInventoryScreen> {
  int index = 0;
  int counted = 0;
  String motif = _motifs.first;
  final Set<String> validated = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = state.products;
    final p = products[index % products.length];
    final theoretical = state.stockOf(p.id, state.currentStoreId).round();
    final gap = counted - theoretical;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventaire — ${state.currentStore.name}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Container(
            height: 132,
            decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: AppRadius.md),
            alignment: Alignment.center,
            child: const Text('Viseur caméra · code-barres', style: TextStyle(color: AppColors.neutral700, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          Text('Dernier scan · ${p.barcode}', style: const TextStyle(fontSize: 13, color: AppColors.neutral700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 17, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusTag('Théorique $theoretical', variant: TagVariant.accent),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(icon: Icons.remove, onTap: () => setState(() => counted = (counted - 1).clamp(0, 1 << 30))),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: Text('$counted', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              _StepButton(icon: Icons.add, onTap: () => setState(() => counted = counted + 1)),
            ],
          ),
          const SizedBox(height: 12),
          if (gap != 0) ...[
            Text('Écart ${gap > 0 ? '+$gap' : gap} — motif requis', style: const TextStyle(color: AppColors.accent2_700, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: motif,
              items: [for (final m in _motifs) DropdownMenuItem(value: m, child: Text(m))],
              onChanged: (v) => setState(() => motif = v ?? motif),
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            label: 'Valider la ligne',
            expand: true,
            onPressed: () async {
              await state.setCountedStock(state.currentStoreId, p.id, counted.toDouble());
              setState(() {
                validated.add(p.id);
                index = (index + 1) % products.length;
                counted = state.stockOf(products[index % products.length].id, state.currentStoreId).round();
                motif = _motifs.first;
              });
            },
          ),
          const SizedBox(height: 8),
          Text('${validated.length} / ${products.length} références comptées', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 22)),
      ),
    );
  }
}
