import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/caisse_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/reception_screen.dart';
import '../screens/transfers_screen.dart';
import '../screens/products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/suppliers_screen.dart';
import '../screens/users_screen.dart';
import '../screens/depots_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/credits_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/invoicing_screen.dart';
import '../screens/establishment_screen.dart';
import '../screens/my_account_screen.dart';
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
    if (!state.authenticated) {
      return const LoginScreen();
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
  _NavItem('depots', 'Dépôts', Icons.home_work_outlined),
  _NavItem('cat', 'Catégories', Icons.category_outlined),
  _NavItem('recep', 'Réception', Icons.local_shipping_outlined),
  _NavItem('trans', 'Transferts', Icons.compare_arrows_outlined),
  _NavItem('prod', 'Produits & prix', Icons.sell_outlined),
  _NavItem('four', 'Fournisseurs', Icons.handshake_outlined),
  _NavItem('clients', 'Clients', Icons.people_outline),
  _NavItem('credits', 'Crédits', Icons.credit_card_outlined),
  _NavItem('notif', 'Notifications', Icons.notifications_outlined),
  _NavItem('dep', 'Dépenses', Icons.payments_outlined),
  _NavItem('fact', 'Facturation', Icons.description_outlined),
  _NavItem('rap', 'Rapports', Icons.bar_chart_outlined),
  _NavItem('users', 'Utilisateurs', Icons.badge_outlined),
  _NavItem('etab', 'Établissement', Icons.apartment_outlined),
  _NavItem('compte', 'Mon compte', Icons.lock_outline),
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
        'depots' => const DepotsScreen(),
        'cat' => const CategoriesScreen(),
        'recep' => const ReceptionScreen(),
        'trans' => const TransfersScreen(),
        'prod' => const ProductsScreen(),
        'four' => const SuppliersScreen(),
        'clients' => const ClientsScreen(),
        'credits' => const CreditsScreen(),
        'notif' => const NotificationsScreen(),
        'dep' => const ExpensesScreen(),
        'fact' => const InvoicingScreen(),
        'rap' => const ReportsScreen(),
        'users' => const UsersScreen(),
        'etab' => const EstablishmentScreen(),
        'compte' => const MyAccountScreen(),
        _ => const DashboardScreen(),
      };
}

class _Sidebar extends StatefulWidget {
  const _Sidebar({required this.state});
  final AppState state;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  AppState get state => widget.state;
  final ScrollController _navScroll = ScrollController();

  @override
  void dispose() {
    _navScroll.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_navScroll.hasClients) return;
    final target = (_navScroll.offset + delta).clamp(0.0, _navScroll.position.maxScrollExtent);
    _navScroll.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  int _badgeFor(String id) => switch (id) {
        'stock' => state.sousSeuilCount,
        'recep' => state.currentReception != null && state.currentReception!.status != 'Conforme' ? 1 : 0,
        'trans' => state.transfers.where((t) => t.status == TransferStatus.aValider).length,
        'four' => state.purchaseOrders.where((p) => p.status != 'Confirmée').length,
        'credits' => state.creditAccounts.where((c) => c.balance >= c.ceiling).length,
        'notif' => state.lowStockAlerts.length +
            state.transfers.where((t) => t.status == TransferStatus.aValider).length +
            state.purchaseOrders.where((p) => p.status != 'Confirmée').length +
            (state.currentReception != null && state.currentReception!.status == 'Écart' ? 1 : 0),
        _ => 0,
      };

  static const _mutedLight = Color(0xB3FFFFFF); // white @ 70% — inactive nav/labels on the dark sidebar
  static const _faintLight = Color(0x80FFFFFF); // white @ 50% — subtitle/dividers

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.accent900,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                  child: const Text('S', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Source Serif 4')),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('SupMag', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                      const Text('Gestion multi-magasins', style: TextStyle(fontSize: 12, color: _faintLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ScrollArrow(icon: Icons.keyboard_arrow_up, onTap: () => _scrollBy(-180)),
          Expanded(
            child: ListView(
              controller: _navScroll,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
          _ScrollArrow(icon: Icons.keyboard_arrow_down, onTap: () => _scrollBy(180)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('MAGASIN ACTIF', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: _faintLight, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.accent800, borderRadius: AppRadius.md),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.currentStoreId,
                      isExpanded: true,
                      dropdownColor: AppColors.accent800,
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      items: [
                        for (final s in state.stores) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => v == null ? null : state.setStore(v),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: _faintLight)),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.accent700,
                      child: Text(
                        (state.currentUser?.name ?? '?').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.currentUser?.name ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(state.currentUser?.role ?? '', style: const TextStyle(color: _mutedLight, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: state.logout,
                      icon: const Icon(Icons.logout, size: 16),
                      tooltip: 'Déconnexion',
                      color: _mutedLight,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small up/down chevron above and below the nav list — the list also
/// scrolls with the mouse wheel, but with 18 items some don't fit the
/// window height, so an explicit affordance keeps them discoverable.
class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 22,
          width: double.infinity,
          child: Icon(icon, size: 18, color: const Color(0xB3FFFFFF)),
        ),
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

  static const _mutedLight = Color(0xB3FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.accent700 : Colors.transparent,
            borderRadius: AppRadius.lg,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: active ? Colors.white : _mutedLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: active ? Colors.white : _mutedLight,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent2_500, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '$badge',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SESSION', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.neutral600)),
              const SizedBox(height: 3),
              Text(sessionLabel, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
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
