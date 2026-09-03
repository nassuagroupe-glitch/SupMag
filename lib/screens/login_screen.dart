import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _gerantRoles = ['Gérant', 'Gérante'];
const _caissierRoles = ['Caissier', 'Caissière'];
const _pinKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '←'];

enum _Step { chooseRole, chooseUser, enterPin }

/// Startup gate shown before the app: pick a role, pick who's signing in,
/// then a 4-digit PIN — or skip straight in via one of the "Travailler hors
/// ligne" shortcuts for a known account. Mirrors the sibling NassuaGroup
/// app's login so staff see the same flow across SupMag's tools.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Step _step = _Step.chooseRole;
  String _roleLabel = '';
  List<String> _roleFilter = const [];
  UserAccount? _selectedUser;
  String _pin = '';
  String? _error;

  void _pickRole(String label, List<String> roles) {
    setState(() {
      _roleLabel = label;
      _roleFilter = roles;
      _step = _Step.chooseUser;
      _error = null;
    });
  }

  void _pickUser(UserAccount user) {
    setState(() {
      _selectedUser = user;
      _step = _Step.enterPin;
      _pin = '';
      _error = null;
    });
  }

  void _pressKey(String key) {
    final state = context.read<AppState>();
    setState(() {
      _error = null;
      if (key == '←') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (key.isEmpty || _pin.length >= 4) return;
      _pin += key;
    });
    if (_pin.length == 4) {
      final user = _selectedUser!;
      if (state.verifyPin(user, _pin)) {
        state.loginAs(user);
      } else {
        setState(() {
          _error = 'Code PIN incorrect';
          _pin = '';
        });
      }
    }
  }

  void _back() {
    setState(() {
      if (_step == _Step.enterPin) {
        _step = _Step.chooseUser;
        _pin = '';
        _error = null;
      } else if (_step == _Step.chooseUser) {
        _step = _Step.chooseRole;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.accent900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.lg,
                boxShadow: AppShadows.lg,
              ),
              child: switch (_step) {
                _Step.chooseRole => _RoleStep(users: state.users, onPickRole: _pickRole, onOfflineLogin: (u) => state.loginAs(u, markOffline: true)),
                _Step.chooseUser => _UserStep(
                    roleLabel: _roleLabel,
                    users: state.users.where((u) => _roleFilter.contains(u.role)).toList(),
                    onPick: _pickUser,
                    onBack: _back,
                  ),
                _Step.enterPin => _PinStep(user: _selectedUser!, pin: _pin, error: _error, onKey: _pressKey, onBack: _back),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.lg),
          child: const Text('S', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Source Serif 4')),
        ),
        const SizedBox(width: 12),
        const Text('SupMag', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Source Serif 4', color: AppColors.text)),
      ],
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({required this.users, required this.onPickRole, required this.onOfflineLogin});
  final List<UserAccount> users;
  final void Function(String label, List<String> roles) onPickRole;
  final void Function(UserAccount user) onOfflineLogin;

  UserAccount? _firstOf(List<String> roles) {
    for (final r in roles) {
      for (final u in users) {
        if (u.role == r) return u;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final offlineCandidates = <UserAccount>[
      ?_firstOf(const ['Direction']),
      ?_firstOf(_gerantRoles),
      ?_firstOf(_caissierRoles),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Brand(),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 56),
          child: Text('Gestion multi-magasins', style: TextStyle(color: AppColors.neutral600)),
        ),
        const SizedBox(height: 26),
        const Text('SE CONNECTER EN TANT QUE', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w600, color: AppColors.neutral600)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => onPickRole('Gérant', _gerantRoles),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent800,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
            ),
            child: const Text('Gérant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => onPickRole('Caissier', _caissierRoles),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.neutral100,
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.neutral300),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
            ),
            child: const Text('Caissier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        if (offlineCandidates.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Divider(height: 1, color: AppColors.divider)),
          for (final u in offlineCandidates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Center(
                child: TextButton(
                  onPressed: () => onOfflineLogin(u),
                  child: Text(
                    'Travailler hors ligne (${u.name} — ${u.role})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.accent700, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _UserStep extends StatelessWidget {
  const _UserStep({required this.roleLabel, required this.users, required this.onPick, required this.onBack});
  final String roleLabel;
  final List<UserAccount> users;
  final void Function(UserAccount user) onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Retour'),
          style: TextButton.styleFrom(foregroundColor: AppColors.neutral700, padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 8),
        Text('Connexion — $roleLabel', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('Choisissez votre compte', style: TextStyle(color: AppColors.neutral600)),
        const SizedBox(height: 18),
        if (users.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Aucun compte avec ce rôle pour le moment.', style: TextStyle(color: AppColors.neutral600)),
          )
        else
          for (final u in users)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.neutral100,
                borderRadius: AppRadius.md,
                child: InkWell(
                  borderRadius: AppRadius.md,
                  onTap: () => onPick(u),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.accent200,
                          child: Text(u.name[0], style: const TextStyle(color: AppColors.accent900, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(u.storeId ?? 'Tous magasins', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.neutral500),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _PinStep extends StatelessWidget {
  const _PinStep({required this.user, required this.pin, required this.error, required this.onKey, required this.onBack});
  final UserAccount user;
  final String pin;
  final String? error;
  final void Function(String key) onKey;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Changer d\'utilisateur'),
          style: TextButton.styleFrom(foregroundColor: AppColors.neutral700, padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.accent200,
                child: Text(user.name[0], style: const TextStyle(color: AppColors.accent900, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(user.role, style: const TextStyle(color: AppColors.neutral600, fontSize: 13)),
              const SizedBox(height: 18),
              const Text('CODE PIN', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600)),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < pin.length ? AppColors.accent800 : AppColors.neutral300,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 20,
                child: error == null
                    ? null
                    : Text(error!, style: const TextStyle(color: AppColors.accent2_700, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.7,
          children: [
            for (final k in _pinKeys)
              k.isEmpty
                  ? const SizedBox.shrink()
                  : Material(
                      color: AppColors.neutral100,
                      borderRadius: AppRadius.md,
                      child: InkWell(
                        borderRadius: AppRadius.md,
                        onTap: () => onKey(k),
                        child: Center(
                          child: k == '←'
                              ? const Icon(Icons.backspace_outlined, size: 18)
                              : Text(k, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
          ],
        ),
      ],
    );
  }
}
