import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'seed.dart';

/// Firestore-backed data layer. Firestore's own offline persistence (cache
/// + write queue, enabled in main.dart) is what gives SupMag its "hors
/// ligne" behaviour now — there is no separate local database: every
/// screen reads/writes straight through this repository, and the SDK
/// transparently serves cached data and queues writes while offline, then
/// syncs when the connection comes back.
///
/// Method names/signatures intentionally mirror the previous sqlite
/// version so AppState didn't need to change when this replaced it.
class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore}) : _fs = firestore ?? FirebaseFirestore.instance;

  /// Swappable for tests: `FirestoreRepository.instance = FirestoreRepository(firestore: FakeFirebaseFirestore());`
  static FirestoreRepository instance = FirestoreRepository();

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> get _stores => _fs.collection('stores');
  CollectionReference<Map<String, dynamic>> get _products => _fs.collection('products');
  CollectionReference<Map<String, dynamic>> get _stock => _fs.collection('stock');
  CollectionReference<Map<String, dynamic>> get _tickets => _fs.collection('tickets');
  CollectionReference<Map<String, dynamic>> get _transfers => _fs.collection('transfers');
  CollectionReference<Map<String, dynamic>> get _suppliers => _fs.collection('suppliers');
  CollectionReference<Map<String, dynamic>> get _purchaseOrders => _fs.collection('purchase_orders');
  CollectionReference<Map<String, dynamic>> get _receptions => _fs.collection('receptions');
  CollectionReference<Map<String, dynamic>> get _users => _fs.collection('users');
  CollectionReference<Map<String, dynamic>> get _creditAccounts => _fs.collection('credit_accounts');
  CollectionReference<Map<String, dynamic>> get _expenses => _fs.collection('expenses');
  DocumentReference<Map<String, dynamic>> get _ticketCounter => _fs.collection('counters').doc('tickets');

  String _stockId(String storeId, String productId) => '${storeId}_$productId';

  // ---- Seeding --------------------------------------------------------------

  /// Populates an empty project with reference + demo data. Safe to call on
  /// every launch: it checks whether `stores` is already populated first.
  Future<void> ensureSeeded() async {
    final existing = await _stores.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    await _seed();
  }

  /// Backfills the `pin` field on the seed users that don't have one yet.
  /// Runs on every launch (not gated like [ensureSeeded]) so accounts
  /// created before PIN login existed pick one up without a full reseed —
  /// but never overwrites a pin an admin already changed from the Users
  /// screen, so it only ever touches docs missing the field entirely.
  Future<void> ensureUserPins() async {
    final existing = await _users.get();
    final missingPin = {for (final d in existing.docs) if (!d.data().containsKey('pin')) d.id};
    if (missingPin.isEmpty) return;
    final batch = _fs.batch();
    for (final u in seedUsers) {
      if (missingPin.contains(u.id)) {
        batch.set(_users.doc(u.id), {'pin': u.pin}, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  Future<void> _commitInChunks(List<(CollectionReference<Map<String, dynamic>>, String, Map<String, Object?>)> writes) async {
    for (var i = 0; i < writes.length; i += 450) {
      final chunk = writes.skip(i).take(450);
      final batch = _fs.batch();
      for (final (col, id, data) in chunk) {
        batch.set(col.doc(id), data);
      }
      await batch.commit();
    }
  }

  Future<void> _seed() async {
    final writes = <(CollectionReference<Map<String, dynamic>>, String, Map<String, Object?>)>[];
    for (final s in stores) {
      writes.add((_stores, s.id, s.toMap()));
    }
    for (final p in products) {
      writes.add((_products, p.id, p.toMap()));
    }
    stockByStore.forEach((storeId, byProduct) {
      byProduct.forEach((productId, qty) {
        writes.add((_stock, _stockId(storeId, productId), StockLevel(storeId: storeId, productId: productId, qty: qty).toMap()));
      });
    });
    for (final s in suppliers) {
      writes.add((_suppliers, s.id, s.toMap()));
    }
    for (final po in purchaseOrders) {
      writes.add((_purchaseOrders, po.id, po.toMap()));
    }
    for (final t in seedTransfers) {
      writes.add((_transfers, t.id, t.toMap()));
    }
    for (final u in seedUsers) {
      writes.add((_users, u.id, u.toMap()));
    }
    for (final c in creditAccounts) {
      writes.add((_creditAccounts, c.id, c.toMap()));
    }
    for (final e in seedExpenses) {
      writes.add((_expenses, e.id, e.toMap()));
    }
    await _commitInChunks(writes);

    final (reception, receptionLinesSeed) = seedReceptions;
    await _receptions.doc(reception.id).set(reception.toMap());
    final rlBatch = _fs.batch();
    for (final l in receptionLinesSeed) {
      rlBatch.set(_receptions.doc(reception.id).collection('lines').doc(l.id), l.toMap());
    }
    await rlBatch.commit();

    await _ticketCounter.set({'value': 4188});

    // Historical demo sales, seeded separately since it's the largest batch.
    final (demoTickets, demoLines) = buildDemoSales(DateTime.now());
    final ticketWrites = [for (final t in demoTickets) (_tickets, t.id, t.toMap())];
    await _commitInChunks(ticketWrites);
    final lineWrites = [
      for (final l in demoLines) (_tickets.doc(l['ticket_id'] as String).collection('lines'), l['id'] as String, l),
    ];
    await _commitInChunks(lineWrites);
  }

  // ---- Reference data ---------------------------------------------------

  Future<List<Store>> allStores() async {
    final snap = await _stores.orderBy('name').get();
    return snap.docs.map((d) => Store.fromMap(d.data())).toList();
  }

  Future<List<Product>> allProducts() async {
    final snap = await _products.orderBy('name').get();
    return snap.docs.map((d) => Product.fromMap(d.data())).toList();
  }

  Future<Product?> product(String id) async {
    final doc = await _products.doc(id).get();
    return doc.exists ? Product.fromMap(doc.data()!) : null;
  }

  Future<void> createProduct(Product p) async {
    await _products.doc(p.id).set(p.toMap());
    final storeList = await allStores();
    final batch = _fs.batch();
    for (final s in storeList) {
      batch.set(_stock.doc(_stockId(s.id, p.id)), StockLevel(storeId: s.id, productId: p.id, qty: 0).toMap());
    }
    await batch.commit();
  }

  Future<void> updateProductPrice(String id, {int? priceBuy, int? priceSell}) async {
    final values = <String, Object?>{};
    if (priceBuy != null) values['price_buy'] = priceBuy;
    if (priceSell != null) values['price_sell'] = priceSell;
    if (values.isEmpty) return;
    await _products.doc(id).update(values);
  }

  // ---- Stock -----------------------------------------------------------

  /// productId -> qty for one store.
  Future<Map<String, double>> stockForStore(String storeId) async {
    final snap = await _stock.where('store_id', isEqualTo: storeId).get();
    return {for (final d in snap.docs) d.data()['product_id'] as String: (d.data()['qty'] as num).toDouble()};
  }

  /// productId -> {storeId: qty} across every store.
  Future<Map<String, Map<String, double>>> stockMatrix() async {
    final snap = await _stock.get();
    final out = <String, Map<String, double>>{};
    for (final d in snap.docs) {
      final data = d.data();
      final pid = data['product_id'] as String;
      out.putIfAbsent(pid, () => {})[data['store_id'] as String] = (data['qty'] as num).toDouble();
    }
    return out;
  }

  Future<void> adjustStock(String storeId, String productId, double delta) async {
    await _stock.doc(_stockId(storeId, productId)).set(
      {'store_id': storeId, 'product_id': productId, 'qty': FieldValue.increment(delta)},
      SetOptions(merge: true),
    );
  }

  Future<void> setStock(String storeId, String productId, double qty) async {
    await _stock.doc(_stockId(storeId, productId)).set(StockLevel(storeId: storeId, productId: productId, qty: qty).toMap());
  }

  // ---- Tickets / sales ---------------------------------------------------

  /// Read-only peek at the next ticket number, for display before a sale is
  /// actually recorded (doesn't consume/increment the counter).
  Future<int> peekNextTicketNo() async {
    final snap = await _ticketCounter.get();
    return (snap.data()?['value'] as int?) ?? 4188;
  }

  Future<int> nextTicketNo() {
    return _fs.runTransaction<int>((tx) async {
      final snap = await tx.get(_ticketCounter);
      final current = (snap.data()?['value'] as int?) ?? 4188;
      tx.set(_ticketCounter, {'value': current + 1});
      return current;
    });
  }

  Future<void> recordSale({
    required String storeId,
    required List<CartLine> lines,
    required String payMethod,
    required bool offline,
  }) async {
    final ticketNo = await nextTicketNo();
    final totalTtc = lines.fold<int>(0, (a, l) => a + l.total);
    final tva = lines.fold<int>(0, (a, l) => a + l.tax);
    final id = 't${DateTime.now().microsecondsSinceEpoch}';
    final createdAt = DateTime.now();

    final batch = _fs.batch();
    batch.set(
      _tickets.doc(id),
      Ticket(
        id: id,
        storeId: storeId,
        ticketNo: ticketNo,
        createdAt: createdAt,
        payMethod: payMethod,
        totalTtc: totalTtc,
        totalHt: totalTtc - tva,
        tva: tva,
        synced: !offline,
      ).toMap(),
    );
    for (final l in lines) {
      batch.set(_tickets.doc(id).collection('lines').doc(l.product.id), {
        'id': '$id-${l.product.id}',
        'ticket_id': id,
        'product_id': l.product.id,
        'qty': l.qty,
        'unit_price': l.product.priceSell,
        'total': l.total,
        'category': l.product.category,
        'store_id': storeId,
        'created_at': createdAt.toIso8601String(),
        'pay_method': payMethod,
      });
      batch.set(
        _stock.doc(_stockId(storeId, l.product.id)),
        {'store_id': storeId, 'product_id': l.product.id, 'qty': FieldValue.increment(-l.qty)},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<Ticket>> ticketsForStore(String storeId, {DateTime? since}) async {
    Query<Map<String, dynamic>> q = _tickets.where('store_id', isEqualTo: storeId);
    if (since != null) q = q.where('created_at', isGreaterThanOrEqualTo: since.toIso8601String());
    final snap = await q.orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => Ticket.fromMap(d.data())).toList();
  }

  Future<List<Ticket>> allTickets({DateTime? since}) async {
    Query<Map<String, dynamic>> q = _tickets;
    if (since != null) q = q.where('created_at', isGreaterThanOrEqualTo: since.toIso8601String());
    final snap = await q.orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => Ticket.fromMap(d.data())).toList();
  }

  Future<List<Map<String, Object?>>> ticketLinesFor(String ticketId) async {
    final snap = await _tickets.doc(ticketId).collection('lines').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _linesSince(DateTime since) async {
    final snap = await _fs.collectionGroup('lines').where('created_at', isGreaterThanOrEqualTo: since.toIso8601String()).get();
    return snap.docs;
  }

  /// Sum of ticket totals per calendar day (yyyy-MM-dd) since [since].
  Future<Map<String, int>> dailyTotals(DateTime since) async {
    final docs = await _linesSince(since);
    final out = <String, int>{};
    for (final d in docs) {
      final data = d.data();
      final day = (data['created_at'] as String).substring(0, 10);
      out[day] = (out[day] ?? 0) + (data['total'] as num).round();
    }
    return out;
  }

  /// category -> total FCFA sold, since [since].
  Future<Map<String, int>> salesByCategory(DateTime since) async {
    final docs = await _linesSince(since);
    final out = <String, int>{};
    for (final d in docs) {
      final data = d.data();
      final cat = data['category'] as String? ?? '—';
      out[cat] = (out[cat] ?? 0) + (data['total'] as num).round();
    }
    return out;
  }

  /// hour-of-day (0-23) -> ticket count, since [since]. Counts lines (not
  /// distinct tickets) as a proxy for activity — good enough for the
  /// "heures de pointe" summary this feeds.
  Future<Map<int, int>> ticketsByHour(DateTime since) async {
    final docs = await _linesSince(since);
    final out = <int, int>{};
    for (final d in docs) {
      final hour = int.parse((d.data()['created_at'] as String).substring(11, 13));
      out[hour] = (out[hour] ?? 0) + 1;
    }
    return out;
  }

  /// Aggregated qty sold per product across all tickets (for "top produits").
  Future<Map<String, double>> unitsSoldByProduct({DateTime? since}) async {
    final docs = since == null ? (await _fs.collectionGroup('lines').get()).docs : await _linesSince(since);
    final out = <String, double>{};
    for (final d in docs) {
      final data = d.data();
      final pid = data['product_id'] as String;
      out[pid] = (out[pid] ?? 0) + (data['total'] as num).toDouble();
    }
    return out;
  }

  // ---- Transfers ---------------------------------------------------------

  Future<List<Transfer>> allTransfers() async {
    final snap = await _transfers.orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => Transfer.fromMap(d.data())).toList();
  }

  Future<void> createTransfer(Transfer t) async {
    await _transfers.doc(t.id).set(t.toMap());
  }

  Future<void> setTransferStatus(String id, TransferStatus status) async {
    await _transfers.doc(id).update({'status': status.name});
    if (status == TransferStatus.recu) {
      final doc = await _transfers.doc(id).get();
      final t = Transfer.fromMap(doc.data()!);
      await adjustStock(t.originStoreId, t.productId, -t.qty);
      await adjustStock(t.destStoreId, t.productId, t.qty);
    }
  }

  // ---- Suppliers / purchase orders ---------------------------------------

  Future<List<Supplier>> allSuppliers() async {
    final snap = await _suppliers.orderBy('name').get();
    return snap.docs.map((d) => Supplier.fromMap(d.data())).toList();
  }

  Future<List<PurchaseOrder>> allPurchaseOrders() async {
    final snap = await _purchaseOrders.orderBy('expected_date').get();
    return snap.docs.map((d) => PurchaseOrder.fromMap(d.data())).toList();
  }

  Future<void> createPurchaseOrder(PurchaseOrder po) async {
    await _purchaseOrders.doc(po.id).set(po.toMap());
  }

  // ---- Receptions --------------------------------------------------------

  Future<List<Reception>> allReceptions() async {
    final snap = await _receptions.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Reception.fromMap(d.data())).toList();
  }

  Future<List<ReceptionLine>> receptionLines(String receptionId) async {
    final snap = await _receptions.doc(receptionId).collection('lines').get();
    return snap.docs.map((d) => ReceptionLine.fromMap(d.data())).toList();
  }

  Future<void> validateReception(Reception reception, List<ReceptionLine> lines) async {
    final batch = _fs.batch();
    batch.set(_receptions.doc(reception.id), reception.toMap());
    for (final l in lines) {
      batch.set(_receptions.doc(reception.id).collection('lines').doc(l.id), l.toMap());
    }
    await batch.commit();
    for (final l in lines) {
      await adjustStock(reception.storeId, l.productId, l.receivedQty);
    }
  }

  // ---- Users --------------------------------------------------------------

  Future<List<UserAccount>> allUsers() async {
    final snap = await _users.orderBy('name').get();
    return snap.docs.map((d) => UserAccount.fromMap(d.data())).toList();
  }

  Future<void> addUser(UserAccount u) async {
    await _users.doc(u.id).set(u.toMap());
  }

  Future<void> setUserPin(String userId, String pin) async {
    await _users.doc(userId).update({'pin': pin});
  }

  // ---- Credit accounts ------------------------------------------------------

  Future<List<CreditAccount>> creditAccountsForStore(String storeId) async {
    final snap = await _creditAccounts.where('store_id', isEqualTo: storeId).get();
    return snap.docs.map((d) => CreditAccount.fromMap(d.data())).toList();
  }

  Future<List<CreditAccount>> allCreditAccounts() async {
    final snap = await _creditAccounts.get();
    return snap.docs.map((d) => CreditAccount.fromMap(d.data())).toList();
  }

  Future<void> addCreditAccount(CreditAccount c) async {
    await _creditAccounts.doc(c.id).set(c.toMap());
  }

  Future<void> setCreditBalance(String id, int balance) async {
    await _creditAccounts.doc(id).update({'balance': balance});
  }

  // ---- Expenses ---------------------------------------------------------

  Future<List<Expense>> allExpenses() async {
    final snap = await _expenses.get();
    return snap.docs.map((d) => Expense.fromMap(d.data())).toList();
  }

  Future<void> addExpense(Expense e) async {
    await _expenses.doc(e.id).set(e.toMap());
  }
}
