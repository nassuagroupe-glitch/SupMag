import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Financial view of the same credit accounts as the Clients directory:
/// exposure vs ceiling per customer, and a quick way to log a repayment.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final total = state.creditAccounts.fold<int>(0, (a, c) => a + c.balance);
    final atCeiling = state.creditAccounts.where((c) => c.balance >= c.ceiling).length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Relation client'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Crédits & ardoises')),
          Wrap(spacing: 24, runSpacing: 12, children: [
            _Kpi(label: 'Encours total', value: '${fmtFcfa(total)} FCFA'),
            _Kpi(label: 'Comptes', value: '${state.creditAccounts.length}'),
            _Kpi(label: 'Au plafond', value: '$atCeiling', color: atCeiling > 0 ? AppColors.accent2_700 : null),
          ]),
          const SizedBox(height: 22),
          for (final c in state.creditAccounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.customerName, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(state.store(c.storeId).name, style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'Enregistrer un paiement',
                          variant: AppButtonVariant.secondary,
                          onPressed: c.balance == 0 ? null : () => _openPaymentDialog(context, state, c.id, c.balance),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LabeledBar(
                      label: 'Solde',
                      valueLabel: '${fmtFcfa(c.balance)} / ${fmtFcfa(c.ceiling)} FCFA',
                      fraction: c.ceiling == 0 ? 0 : c.balance / c.ceiling,
                      color: c.balance >= c.ceiling ? AppColors.accent2_500 : AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPaymentDialog(BuildContext context, AppState state, String creditId, int maxAmount) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer un paiement'),
        content: SizedBox(
          width: 280,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Montant reçu (FCFA)', helperText: 'Solde actuel : ${fmtFcfa(maxAmount)} FCFA'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text.trim()) ?? 0;
              if (amount <= 0) return;
              await state.recordCreditPayment(creditId, amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 1.2, color: AppColors.neutral600)),
        Text(value, style: TextStyle(fontFamily: 'Source Serif 4', fontSize: 24, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
