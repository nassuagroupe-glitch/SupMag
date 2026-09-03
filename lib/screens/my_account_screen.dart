import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Session'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Mon compte')),
          if (user == null)
            const Text('Aucune session active.', style: TextStyle(color: AppColors.neutral600))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.accent200,
                          child: Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.accent900, fontWeight: FontWeight.w700, fontSize: 17)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(user.role, style: const TextStyle(color: AppColors.neutral700)),
                          ],
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    _Row('Magasin', user.storeId == null ? 'Tous magasins' : state.store(user.storeId!).name),
                    _Row('Appareil', user.device),
                    _Row('Statut', user.status),
                    const SizedBox(height: 18),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      AppButton(label: 'Changer mon code PIN', variant: AppButtonVariant.secondary, onPressed: () => _openPinDialog(context, state, user.id, user.name)),
                      AppButton(label: 'Se déconnecter', variant: AppButtonVariant.ghost, onPressed: state.logout),
                    ]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPinDialog(BuildContext context, AppState state, String userId, String userName) async {
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('Nouveau code PIN — $userName'),
          content: SizedBox(
            width: 260,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(labelText: 'Code à 4 chiffres', errorText: error, counterText: ''),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final pin = controller.text.trim();
                if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                  setDialogState(() => error = 'Le code doit contenir exactement 4 chiffres');
                  return;
                }
                await state.setUserPin(userId, pin);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
