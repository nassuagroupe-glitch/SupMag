import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/firestore_repository.dart';
import '../data/local_settings.dart';
import '../models/models.dart';

const _uuid = Uuid();

class LowStockAlert {
  final Product product;
  final Store store;
  final double qty;
  final bool rupture; // qty == 0
  LowStockAlert({required this.product, required this.store, required this.qty, required this.rupture});
}

/// Single app-wide store. Loads everything from Firestore on [init] and
/// keeps an in-memory cache that screens read synchronously; every mutating
/// action re-reads the affected slice afterwards and calls notifyListeners().
/// Firestore's own offline cache/queue is what makes this work without a
/// network connection — see main.dart for where persistence is enabled.
class AppState extends ChangeNotifier {
  final FirestoreRepository _db = FirestoreRepository.instance;
  final LocalSettings _local = LocalSettings.instance;
  bool ready = false;

  List<Store> stores = [];
  List<Product> products = [];
  List<Supplier> suppliers = [];
  List<PurchaseOrder> purchaseOrders = [];
  List<Transfer> transfers = [];
  Reception? currentReception;
  List<ReceptionLine> currentReceptionLines = [];
  List<UserAccount> users = [];
  List<CreditAccount> creditAccounts = [];
  Map<String, Map<String, double>> stockMatrix = {}; // productId -> storeId -> qty
  Map<String, double> unitsSoldByProduct = {}; // last 30 days
  Map<String, double> unitsSoldByProduct7d = {}; // last 7 days, for "Top produits"
  List<Ticket> recentTickets = []; // last 30 days
  List<Ticket> todayTickets = [];
  Map<String, int> dailyTotals30d = {}; // yyyy-MM-dd -> FCFA
  Map<String, int> salesByCategory30d = {}; // category -> FCFA
  Map<int, int> ticketsByHour30d = {}; // hour -> count

  late Map<String, Product> _productsById;
  late Map<String, Store> _storesById;
  late Map<String, Supplier> _suppliersById;

  Product product(String id) => _productsById[id]!;
  Store store(String id) => _storesById[id]!;
  Supplier supplier(String id) => _suppliersById[id]!;

  // ---- Session / navigation ------------------------------------------------

  String currentStoreId = 'yopougon';
  Store get currentStore => store(currentStoreId);

  bool offline = false;
  String caisseVariant = 'grille'; // 'grille' | 'scan'
  String desktopScreen = 'dash';
  int mobileTab = 0;

  // ---- Caisse (POS) working state -----------------------------------------

  final List<CartLine> cart = [];
  String query = '';
  String keypad = '';
  String payMethod = 'Espèces';
  ({int no, int amount, String pay})? receipt;
  int _ticketPreview = 4188;

  Future<void> init() async {
    await _db.ensureSeeded();
    stores = await _db.allStores();
    products = await _db.allProducts();
    suppliers = await _db.allSuppliers();
    _productsById = {for (final p in products) p.id: p};
    _storesById = {for (final s in stores) s.id: s};
    _suppliersById = {for (final s in suppliers) s.id: s};

    final savedStore = await _local.getString('current_store');
    if (savedStore != null && _storesById.containsKey(savedStore)) currentStoreId = savedStore;
    final savedVariant = await _local.getString('caisse_variant');
    if (savedVariant != null) caisseVariant = savedVariant;
    final savedOffline = await _local.getString('offline');
    offline = savedOffline == '1';

    await Future.wait([
      refreshStock(notify: false),
      refreshTransfers(notify: false),
      refreshPurchaseOrders(notify: false),
      refreshUsers(notify: false),
      refreshCreditAccounts(notify: false),
      refreshSales(notify: false),
      _loadReception(),
    ]);

    ready = true;
    notifyListeners();
  }

  Future<void> _loadReception() async {
    final receptions = await _db.allReceptions();
    if (receptions.isEmpty) return;
    currentReception = receptions.first;
    currentReceptionLines = await _db.receptionLines(currentReception!.id);
  }

  Future<void> refreshStock({bool notify = true}) async {
    stockMatrix = await _db.stockMatrix();
    if (notify) notifyListeners();
  }

  Future<void> refreshTransfers({bool notify = true}) async {
    transfers = await _db.allTransfers();
    if (notify) notifyListeners();
  }

  Future<void> refreshPurchaseOrders({bool notify = true}) async {
    purchaseOrders = await _db.allPurchaseOrders();
    if (notify) notifyListeners();
  }

  Future<void> refreshUsers({bool notify = true}) async {
    users = await _db.allUsers();
    if (notify) notifyListeners();
  }

  Future<void> refreshCreditAccounts({bool notify = true}) async {
    creditAccounts = await _db.allCreditAccounts();
    if (notify) notifyListeners();
  }

  Future<void> refreshSales({bool notify = true}) async {
    final now = DateTime.now();
    final since30 = now.subtract(const Duration(days: 30));
    final since7 = now.subtract(const Duration(days: 7));
    final startOfToday = DateTime(now.year, now.month, now.day);
    recentTickets = await _db.allTickets(since: since30);
    unitsSoldByProduct = await _db.unitsSoldByProduct(since: since30);
    unitsSoldByProduct7d = await _db.unitsSoldByProduct(since: since7);
    todayTickets = recentTickets.where((t) => !t.createdAt.isBefore(startOfToday)).toList();
    dailyTotals30d = await _db.dailyTotals(since30);
    salesByCategory30d = await _db.salesByCategory(since30);
    ticketsByHour30d = await _db.ticketsByHour(since30);
    _ticketPreview = await _db.peekNextTicketNo();
    if (notify) notifyListeners();
  }

  // ---- Stock helpers --------------------------------------------------------

  double stockOf(String productId, String storeId) => stockMatrix[productId]?[storeId] ?? 0;

  double totalStockOf(String productId) => (stockMatrix[productId] ?? const {}).values.fold(0.0, (a, b) => a + b);

  List<LowStockAlert> get lowStockAlerts {
    final out = <LowStockAlert>[];
    for (final p in products) {
      final byStore = stockMatrix[p.id] ?? const {};
      byStore.forEach((storeId, qty) {
        if (qty <= p.threshold) {
          out.add(LowStockAlert(product: p, store: store(storeId), qty: qty, rupture: qty == 0));
        }
      });
    }
    return out;
  }

  int get ruptureCount => lowStockAlerts.where((a) => a.rupture).length;
  int get sousSeuilCount => lowStockAlerts.where((a) => !a.rupture).length;

  double get totalStockValueFcfa {
    double v = 0;
    for (final p in products) {
      v += totalStockOf(p.id) * p.priceSell;
    }
    return v;
  }

  // ---- Navigation / settings actions -----------------------------------

  void setStore(String id) {
    currentStoreId = id;
    _local.setString('current_store', id);
    notifyListeners();
  }

  void toggleOffline() {
    offline = !offline;
    _local.setString('offline', offline ? '1' : '0');
    notifyListeners();
  }

  void setCaisseVariant(String v) {
    caisseVariant = v;
    _local.setString('caisse_variant', v);
    notifyListeners();
  }

  void setDesktopScreen(String id) {
    desktopScreen = id;
    notifyListeners();
  }

  void setMobileTab(int i) {
    mobileTab = i;
    notifyListeners();
  }

  // ---- Caisse cart -----------------------------------------------------

  List<Product> matchingProducts() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) => p.name.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q)).toList();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void pressKey(String k) {
    keypad = k == '←' ? (keypad.isEmpty ? keypad : keypad.substring(0, keypad.length - 1)) : keypad + k;
    notifyListeners();
  }

  void addToCart(String productId) {
    final p = product(productId);
    final step = p.vrac ? (double.tryParse(keypad.replaceAll(',', '.')) ?? 1) : (int.tryParse(keypad) ?? 1);
    final i = cart.indexWhere((l) => l.product.id == productId);
    if (i >= 0) {
      cart[i].qty += step;
    } else {
      cart.add(CartLine(product: p, qty: step.toDouble()));
    }
    keypad = '';
    query = '';
    receipt = null;
    notifyListeners();
  }

  void bump(String productId, double delta) {
    final i = cart.indexWhere((l) => l.product.id == productId);
    if (i < 0) return;
    final next = double.parse((cart[i].qty + delta).toStringAsFixed(2));
    if (next <= 0) {
      cart.removeAt(i);
    } else {
      cart[i].qty = next;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((l) => l.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    receipt = null;
    notifyListeners();
  }

  void setPayMethod(String m) {
    payMethod = m;
    notifyListeners();
  }

  int get cartTotalTtc => cart.fold(0, (a, l) => a + l.total);
  int get cartTva => cart.fold(0, (a, l) => a + l.tax);
  int get cartExonere => cart.where((l) => l.product.tva == 0).fold(0, (a, l) => a + l.total);

  int get ticketPreviewNo => _ticketPreview;

  Future<void> validateSale() async {
    if (cart.isEmpty) return;
    final no = _ticketPreview;
    final amount = cartTotalTtc;
    final pay = payMethod;
    await _db.recordSale(storeId: currentStoreId, lines: List.of(cart), payMethod: pay, offline: offline);
    cart.clear();
    keypad = '';
    receipt = (no: no, amount: amount, pay: pay);
    await Future.wait([refreshStock(notify: false), refreshSales(notify: false)]);
    notifyListeners();
  }

  /// Best store to pull [productId] from to restock [excludeStoreId] — the
  /// store (other than the one asking) currently holding the most of it.
  String? bestSourceStoreFor(String productId, String excludeStoreId) {
    final byStore = stockMatrix[productId] ?? const {};
    String? best;
    double bestQty = 0;
    byStore.forEach((storeId, qty) {
      if (storeId == excludeStoreId) return;
      if (qty > bestQty) {
        bestQty = qty;
        best = storeId;
      }
    });
    return best;
  }

  // ---- Transfers ---------------------------------------------------------

  Future<void> createTransfer({
    required String originStoreId,
    required String destStoreId,
    required String productId,
    required double qty,
  }) async {
    final p = product(productId);
    final ref = 'TR-${2500 + transfers.length}';
    final t = Transfer(
      id: _uuid.v4(),
      ref: ref,
      originStoreId: originStoreId,
      destStoreId: destStoreId,
      productId: productId,
      qty: qty,
      value: (qty * p.priceSell).round(),
      transport: 'À affecter',
      status: TransferStatus.aValider,
      createdAt: DateTime.now(),
    );
    await _db.createTransfer(t);
    await refreshTransfers(notify: false);
    notifyListeners();
  }

  Future<void> advanceTransfer(Transfer t) async {
    final next = switch (t.status) {
      TransferStatus.aValider => TransferStatus.enRoute,
      TransferStatus.enRoute => TransferStatus.recu,
      TransferStatus.recu => TransferStatus.recu,
      TransferStatus.ecart => TransferStatus.recu,
    };
    await _db.setTransferStatus(t.id, next);
    await Future.wait([refreshTransfers(notify: false), refreshStock(notify: false)]);
    notifyListeners();
  }

  // ---- Réception -----------------------------------------------------------

  void setReceivedQty(String productId, double qty) {
    final i = currentReceptionLines.indexWhere((l) => l.productId == productId);
    if (i < 0) return;
    currentReceptionLines[i] = ReceptionLine(
      id: currentReceptionLines[i].id,
      receptionId: currentReceptionLines[i].receptionId,
      productId: productId,
      lot: currentReceptionLines[i].lot,
      expiry: currentReceptionLines[i].expiry,
      expectedQty: currentReceptionLines[i].expectedQty,
      receivedQty: qty,
      buyPrice: currentReceptionLines[i].buyPrice,
    );
    notifyListeners();
  }

  Future<void> validateReception() async {
    if (currentReception == null) return;
    final hasGap = currentReceptionLines.any((l) => l.gap != 0);
    final updated = Reception(
      id: currentReception!.id,
      ref: currentReception!.ref,
      supplierId: currentReception!.supplierId,
      storeId: currentReception!.storeId,
      date: currentReception!.date,
      status: hasGap ? 'Écart' : 'Conforme',
    );
    await _db.validateReception(updated, currentReceptionLines);
    currentReception = updated;
    await refreshStock(notify: false);
    notifyListeners();
  }

  // ---- Fournisseurs ----------------------------------------------------

  Future<void> generateSuggestedPurchaseOrders() async {
    var n = purchaseOrders.length;
    for (final supplier in suppliers.take(3)) {
      n++;
      final po = PurchaseOrder(
        id: _uuid.v4(),
        ref: 'CD-${1190 + n}',
        supplierId: supplier.id,
        expectedDate: DateTime.now().add(const Duration(days: 5)),
        linesCount: 3,
        amount: 500000 + n * 10000,
        paymentTerms: supplier.paymentTerms,
        status: 'En attente',
      );
      await _db.createPurchaseOrder(po);
    }
    await refreshPurchaseOrders(notify: false);
    notifyListeners();
  }

  // ---- Barcode inventory count (Android) ----------------------------------

  Future<void> setCountedStock(String storeId, String productId, double qty) async {
    await _db.setStock(storeId, productId, qty);
    await refreshStock(notify: false);
    notifyListeners();
  }

  // ---- Products ----------------------------------------------------------

  Future<void> addProduct(Product p) async {
    await _db.createProduct(p);
    products = await _db.allProducts();
    _productsById = {for (final x in products) x.id: x};
    await refreshStock(notify: false);
    notifyListeners();
  }

  Future<void> updateProductPrice(String id, {int? priceBuy, int? priceSell}) async {
    await _db.updateProductPrice(id, priceBuy: priceBuy, priceSell: priceSell);
    products = await _db.allProducts();
    _productsById = {for (final x in products) x.id: x};
    notifyListeners();
  }

  // ---- Users -----------------------------------------------------------

  Future<void> inviteUser({required String name, required String role, String? storeId, required String device}) async {
    final u = UserAccount(
      id: _uuid.v4(),
      name: name,
      role: role,
      storeId: storeId,
      device: device,
      lastActive: DateTime.now(),
      status: 'Invité',
    );
    await _db.addUser(u);
    await refreshUsers(notify: false);
    notifyListeners();
  }
}
