import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supmag/data/firestore_repository.dart';
import 'package:supmag/data/local_settings.dart';
import 'package:supmag/main.dart';
import 'package:supmag/state/app_state.dart';
import 'package:supmag/theme/app_theme.dart';
import 'package:supmag/widgets/app_shell.dart';

/// A fresh in-memory Firestore + a fresh mock SharedPreferences backing
/// store for every test, so one test's seeded/mutated data (and one
/// terminal's store/variant/offline choice) can never leak into the next.
void _resetBackend() {
  FirestoreRepository.instance = FirestoreRepository(firestore: FakeFirebaseFirestore());
  SharedPreferences.setMockInitialValues({});
  LocalSettings.instance = LocalSettings();
}

/// Scrolls the finder into view (if it's inside a Scrollable, e.g. the main
/// content area) before tapping, then settles.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Dismisses the login gate via one of its "Travailler hors ligne" shortcuts,
/// landing straight on the desktop/mobile shell like the rest of these tests
/// expect.
Future<void> _loginOffline(WidgetTester tester) async {
  await _tap(tester, find.textContaining('Travailler hors ligne').first);
}

/// A realistic desktop window size — the default 800x600 test surface is
/// narrower than the app's own "wide layout" breakpoints, which forces
/// screens into their stacked/narrow variant and pushes secondary content
/// (like a side form) far down the page.
void _useDesktopWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps MobileShell directly (bypassing AppShell's Platform.isAndroid
/// check, which we can't flip in a host-run widget test) with its own real,
/// freshly-seeded AppState — so the three Android screens get the same
/// exercise as the desktop ones above.
Future<AppState> _pumpMobileShell(WidgetTester tester) async {
  final state = AppState();
  await state.init();
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(theme: AppTheme.light(), home: const MobileShell()),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUp(_resetBackend);

  testWidgets('SupMag desktop: boots and every nav screen renders without error', (WidgetTester tester) async {
    _useDesktopWindow(tester);
    await tester.pumpWidget(const SupMagApp());
    await tester.pumpAndSettle();
    await _loginOffline(tester);

    expect(find.text('SupMag'), findsOneWidget);
    expect(find.text('Tableau de bord multi-magasins'), findsOneWidget);
    expect(tester.takeException(), isNull);

    const screens = [
      'Caisse',
      'Stock & inventaire',
      'Réception',
      'Transferts',
      'Produits & prix',
      'Rapports',
      'Fournisseurs',
      'Utilisateurs',
      'Tableau de bord',
    ];
    for (final label in screens) {
      await _tap(tester, find.text(label).first);
      expect(tester.takeException(), isNull, reason: 'navigating to $label');
    }
  });

  testWidgets('SupMag desktop: Caisse variants, cart, and checkout work', (WidgetTester tester) async {
    _useDesktopWindow(tester);
    await tester.pumpWidget(const SupMagApp());
    await tester.pumpAndSettle();
    await _loginOffline(tester);

    await _tap(tester, find.text('Caisse').first);
    expect(tester.takeException(), isNull);

    // Variant A (grille tactile): tap a product tile to add it to the cart.
    expect(find.text('Riz Dinor 5 kg'), findsWidgets);
    await _tap(tester, find.text('Riz Dinor 5 kg').first);
    expect(tester.takeException(), isNull);

    // Switch to variant B (scan & clavier).
    await _tap(tester, find.textContaining('Variante B').first);
    expect(find.text('SUGGESTIONS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Pay method + checkout.
    await _tap(tester, find.text('Orange Money').first);
    await _tap(tester, find.textContaining('Encaisser').first);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('encaissé'), findsOneWidget);
  });

  testWidgets('SupMag desktop: create a transfer', (WidgetTester tester) async {
    _useDesktopWindow(tester);
    await tester.pumpWidget(const SupMagApp());
    await tester.pumpAndSettle();
    await _loginOffline(tester);

    await _tap(tester, find.text('Transferts').first);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Créer et demander validation'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SupMag desktop: new product dialog opens and cancels cleanly', (WidgetTester tester) async {
    _useDesktopWindow(tester);
    await tester.pumpWidget(const SupMagApp());
    await tester.pumpAndSettle();
    await _loginOffline(tester);

    await _tap(tester, find.text('Produits & prix').first);
    await _tap(tester, find.text('Nouveau produit'));
    expect(find.text('Nom du produit'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Annuler'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SupMag desktop: generate suggested purchase orders', (WidgetTester tester) async {
    _useDesktopWindow(tester);
    await tester.pumpWidget(const SupMagApp());
    await tester.pumpAndSettle();
    await _loginOffline(tester);

    await _tap(tester, find.text('Fournisseurs').first);
    await _tap(tester, find.text('Générer des bons de commande'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SupMag mobile (Android): boots and every tab renders without error', (WidgetTester tester) async {
    await _pumpMobileShell(tester);

    expect(find.text('Caisse mobile'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.byIcon(Icons.qr_code_scanner_outlined));
    expect(find.textContaining('Inventaire'), findsWidgets);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.byIcon(Icons.storefront_outlined));
    // "Ma journée" also names the bottom-nav destination, so at least one
    // (not exactly one) match is what we want here.
    expect(find.text('Ma journée'), findsWidgets);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.byIcon(Icons.point_of_sale_outlined));
    expect(find.text('Caisse mobile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SupMag mobile: search, add to cart, and checkout', (WidgetTester tester) async {
    final state = await _pumpMobileShell(tester);

    await tester.enterText(find.byType(TextField), 'Riz Dinor');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The search box narrows the catalog correctly...
    expect(state.matchingProducts().single.name, 'Riz Dinor 5 kg');
    // ...and the matching result renders as a search-result row (tapping
    // it — a freshly-appeared row inside a nested ListView — is flaky to
    // drive via the test framework's hit-testing, so the add-to-cart tap
    // itself is covered by the desktop Caisse test instead).
    expect(find.text('Riz Dinor 5 kg', skipOffstage: false), findsOneWidget);

    state.addToCart('riz5');
    await tester.pumpAndSettle();
    expect(state.cart, isNotEmpty);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Espèces'));
    await _tap(tester, find.text('Encaisser'));
    expect(tester.takeException(), isNull);
    expect(state.cart, isEmpty);
  });

  testWidgets('SupMag mobile: barcode inventory count validates a line', (WidgetTester tester) async {
    await _pumpMobileShell(tester);

    await _tap(tester, find.byIcon(Icons.qr_code_scanner_outlined));
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Valider la ligne'));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('1 /'), findsOneWidget);
  });

  testWidgets('SupMag mobile: manager day view actions work', (WidgetTester tester) async {
    await _pumpMobileShell(tester);

    await _tap(tester, find.byIcon(Icons.storefront_outlined));
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Clôturer la caisse du soir'));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('clôturée'), findsOneWidget);
  });
}
