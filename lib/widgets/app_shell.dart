import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/dashboard_screen.dart';
import '../screens/caisse_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/reception_screen.dart';
import '../screens/transfers_screen.dart';
import '../screens/products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/suppliers_screen.dart';
import '../screens/users_screen.dart';
import '../screens/mobile/mobile_caisse_screen.dart';
import '../screens/mobile/mobile_inventory_screen.dart';
import '../screens/mobile/mobile_manager_screen.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Root of the app: picks the desktop (sidebar) or mobile (bottom-nav) shell.
/// SupMag ships two builds from one codebase — Windows uses the full
/// multi-store back-office, Android uses the three field-facing screens
/// (mobile till, barcode inventory count, manager's daily view).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  bool get _isMobileTarget {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false; // platform without dart:io (shouldn't happen for our two targets)
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isMobileTarget ? const MobileShell() : const DesktopShell();
  }
}

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  const _NavItem(this.id, this.label, this.icon);
}

const _desktopNav = <_NavItem>[
  _NavItem('dash', 'Tableau de bord', Icons.dashboard_outlined),
  _NavItem('caisse', 'Caisse', Icons.point_of_sale_outlined),
  _NavItem('stock', 'Stock & inventaire', Icons.inventory_2_outlined),
  _NavItem('recep', 'Réception', Icons.local_shipping_outlined),
  _NavItem('trans', 'Transferts', Icons.compare_arrows_outlined),
  _NavItem('prod', 'Produits & prix', Icons.sell_outlined),
  _NavItem('rap', 'Rapports', Icons.bar_chart_outlined),
  _NavItem('four', 'Fournisseurs', Icons.handshake_outlined),
  _NavItem('users', 'Utilisateurs', Icons.badge_outlined),
];

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(state: state),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(state: state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                    child: _screenFor(state.desktopScreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenFor(String id) => switch (id) {
        'dash' => const DashboardScreen(),
        'caisse' => const CaisseScreen(),
        'stock' => const StockScreen(),
        'recep' => const ReceptionScreen(),
        'trans' => const TransfersScreen(),
        'prod' => const ProductsScreen(),
        'rap' => const ReportsScreen(),
        'four' => const SuppliersScreen(),
        'users' => const UsersScreen(),
        _ => const DashboardScreen(),
      };
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});
  final AppState state;

  int _badgeFor(String id) => switch (id) {
        'stock' => state.sousSeuilCount,
        'recep' => state.currentReception != null && state.currentReception!.status != 'Conforme' ? 1 : 0,
        'trans' => state.transfers.where((t) => t.status == TransferStatus.aValider).length,
        'four' => state.purchaseOrders.where((p) => p.status != 'Confirmée').length,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      color: AppColors.neutral100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SupMag', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                const Text(
                  'GESTION MULTI-MAGASINS · CI',
                  style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final item in _desktopNav)
                  _NavButton(
                    item: item,
                    active: state.desktopScreen == item.id,
                    badge: _badgeFor(item.id),
                    onTap: () => state.setDesktopScreen(item.id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.offline ? AppColors.accent2_500 : AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        state.offline ? 'Hors ligne — 3 tickets en file' : 'Synchronisé il y a 1 min',
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'K. Aboa — Direction\nVersion 1.0 · Windows · Android',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.badge, required this.onTap});
  final _NavItem item;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.accent200 : Colors.transparent,
            borderRadius: AppRadius.md,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 15,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 9),
              Icon(item.icon, size: 17, color: active ? AppColors.accent900 : AppColors.text),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: active ? AppColors.accent900 : AppColors.text,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badge > 0)
                Text(
                  '$badge',
                  style: const TextStyle(fontSize: 11, color: AppColors.accent2_700, fontFeatures: [FontFeature.tabularFigures()]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = const ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'][now.weekday - 1];
    final months = const ['jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    final sessionLabel = '$weekday ${now.day} ${months[now.month - 1]} ${now.year} — '
        '${now.hour.toString().padLeft(2, '0')}h${now.minute.toString().padLeft(2, '0')} GMT';

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 15),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 20,
        runSpacing: 12,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 15,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 240,
                child: LabeledField(
                  label: 'Magasin actif',
                  child: DropdownButtonFormField<String>(
                    initialValue: state.currentStoreId,
                    isExpanded: true,
                    items: [
                      for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => v == null ? null : state.setStore(v),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SESSION', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.neutral600)),
                  const SizedBox(height: 3),
                  Text(sessionLabel, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusTag('${state.stores.length} magasins', variant: TagVariant.outline),
              if (state.ruptureCount > 0) StatusTag('${state.ruptureCount} ruptures', variant: TagVariant.accent2),
              AppButton(
                label: state.offline ? 'Mode hors ligne actif' : 'Passer hors ligne',
                variant: AppButtonVariant.secondary,
                onPressed: state.toggleOffline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile (Android) shell
// ---------------------------------------------------------------------------

class MobileShell extends StatelessWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    const screens = [MobileCaisseScreen(), MobileInventoryScreen(), MobileManagerScreen()];
    return Scaffold(
      body: SafeArea(child: screens[state.mobileTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.mobileTab,
        onDestinationSelected: state.setMobileTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Caisse'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Inventaire'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Ma journée'),
        ],
      ),
    );
  }
}
