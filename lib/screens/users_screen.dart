import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const _roles = ['Direction', 'Gérant(e)', 'Caissier(ère)', 'Magasinier', 'Comptable'];

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String query = '';
  final Set<String> _revealedPins = {};

  TagVariant _statusVariant(String s) => switch (s) {
        'Actif' || 'En caisse' => TagVariant.accent,
        'Hors ligne' => TagVariant.outline,
        'Invité' => TagVariant.accent2,
        _ => TagVariant.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var users = state.users;
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      users = users.where((u) => u.name.toLowerCase().contains(q) || u.role.toLowerCase().contains(q)).toList();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Administration'),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.only(bottom: 20), child: ScreenTitle('Utilisateurs & rôles')),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 780;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  AppButton(label: 'Inviter un utilisateur', onPressed: () => _openInviteDialog(context, state)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'Rechercher…'))),
                ]),
                const SizedBox(height: 16),
                HScrollTable(
                  minWidth: 700,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Rôle')),
                      DataColumn(label: Text('Magasin')),
                      DataColumn(label: Text('Appareil')),
                      DataColumn(label: Text('Dernière activité')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Code PIN')),
                    ],
                    rows: [
                      for (final u in users)
                        DataRow(cells: [
                          DataCell(Text(u.name)),
                          DataCell(Text(u.role)),
                          DataCell(Text(u.storeId == null ? 'Tous' : state.store(u.storeId!).name)),
                          DataCell(Text(u.device)),
                          DataCell(Text(_relative(u.lastActive))),
                          DataCell(StatusTag(u.status, variant: _statusVariant(u.status))),
                          DataCell(_PinCell(
                            user: u,
                            revealed: _revealedPins.contains(u.id),
                            onToggleReveal: () => setState(() {
                              _revealedPins.contains(u.id) ? _revealedPins.remove(u.id) : _revealedPins.add(u.id);
                            }),
                            onEdit: () => _openPinDialog(context, state, u),
                          )),
                        ]),
                    ],
                  ),
                ),
              ],
            );
            const right = _PermissionsColumn();
            if (narrow) return Column(children: [left, const SizedBox(height: 24), right]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 40), SizedBox(width: 340, child: right)],
            );
          }),
        ],
      ),
    );
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  Future<void> _openInviteDialog(BuildContext context, AppState state) async {
    final name = TextEditingController();
    var role = _roles.first;
    var storeId = state.stores.first.id;
    var device = 'Windows';
    var allStores = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Inviter un utilisateur'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom complet')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: [for (final r in _roles) DropdownMenuItem(value: r, child: Text(r))],
                  onChanged: (v) => setDialogState(() => role = v ?? role),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: allStores,
                  onChanged: (v) => setDialogState(() => allStores = v ?? true),
                  title: const Text('Accès à tous les magasins (Direction/Comptable)'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!allStores)
                  DropdownButtonFormField<String>(
                    initialValue: storeId,
                    decoration: const InputDecoration(labelText: 'Magasin'),
                    items: [for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name))],
                    onChanged: (v) => setDialogState(() => storeId = v ?? storeId),
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: device,
                  decoration: const InputDecoration(labelText: 'Appareil'),
                  items: const [DropdownMenuItem(value: 'Windows', child: Text('Windows')), DropdownMenuItem(value: 'Android', child: Text('Android'))],
                  onChanged: (v) => setDialogState(() => device = v ?? device),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                final created = await state.inviteUser(name: name.text.trim(), role: role, storeId: allStores ? null : storeId, device: device);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${created.name} — code PIN attribué : ${created.pin}')),
                  );
                }
              },
              child: const Text('Envoyer l\'invitation'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openPinDialog(BuildContext context, AppState state, UserAccount user) async {
    final controller = TextEditingController(text: user.pin);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('Code PIN — ${user.name}'),
          content: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(labelText: 'Nouveau code (4 chiffres)', errorText: error, counterText: ''),
                ),
              ],
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
                await state.setUserPin(user.id, pin);
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

class _PinCell extends StatelessWidget {
  const _PinCell({required this.user, required this.revealed, required this.onToggleReveal, required this.onEdit});
  final UserAccount user;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          child: Text(
            revealed ? user.pin : '••••',
            style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: Icon(revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
          onPressed: onToggleReveal,
          tooltip: revealed ? 'Masquer' : 'Afficher',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16),
          onPressed: onEdit,
          tooltip: 'Modifier le code',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

class _PermissionsColumn extends StatelessWidget {
  const _PermissionsColumn();

  static const _rows = [
    ('Encaisser', true, true, true),
    ('Annuler un ticket', false, true, true),
    ('Remise / prix libre', false, true, true),
    ('Ouvrir une ardoise', false, true, true),
    ('Valider une réception', false, true, true),
    ('Modifier les prix', false, false, true),
    ('Voir tous les magasins', false, false, true),
  ];

  @override
  Widget build(BuildContext context) {
    Widget mark(bool v) => Center(child: v ? const Icon(Icons.check, size: 16, color: AppColors.accent700) : const Text('—', style: TextStyle(color: AppColors.neutral500)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Droits par rôle', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        DataTable(
          columnSpacing: 14,
          columns: const [
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Cais.')),
            DataColumn(label: Text('Gér.')),
            DataColumn(label: Text('Dir.')),
          ],
          rows: [
            for (final (action, c, g, d) in _rows)
              DataRow(cells: [DataCell(Text(action)), DataCell(mark(c)), DataCell(mark(g)), DataCell(mark(d))]),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Connexion par code PIN à 4 chiffres sur Android, mot de passe + PIN sur Windows. Chaque action sensible reste tracée dans le journal d\'audit.',
          style: TextStyle(fontSize: 13, color: AppColors.neutral700),
        ),
      ],
    );
  }
}
