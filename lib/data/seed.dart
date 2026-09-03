/// Static reference/demo data mirroring the values shown in the original
/// SupMag.dc.html prototype. Loaded into Firestore once on first launch by
/// FirestoreRepository.ensureSeeded().
library;

import 'dart:math';

import '../models/models.dart';

const stores = <Store>[
  Store(id: 'yopougon', name: 'Yopougon Marché', city: 'Abidjan'),
  Store(id: 'cocody', name: 'Cocody Angré', city: 'Abidjan'),
  Store(id: 'adjame', name: 'Adjamé Liberté', city: 'Abidjan'),
  Store(id: 'treichville', name: 'Treichville Arras', city: 'Abidjan'),
  Store(id: 'abobo', name: 'Abobo Gare', city: 'Abidjan'),
  Store(id: 'marcory', name: 'Marcory Zone 4', city: 'Abidjan'),
  Store(id: 'koumassi', name: 'Koumassi Grand', city: 'Abidjan'),
  Store(id: 'bouake', name: 'Bouaké Commerce', city: 'Bouaké'),
  Store(id: 'daloa', name: 'Daloa Centre', city: 'Daloa'),
  Store(id: 'sanpedro', name: 'San-Pédro Port', city: 'San-Pédro'),
];

const products = <Product>[
  Product(id: 'riz5', name: 'Riz Dinor 5 kg', category: 'Céréales', unit: 'sac', barcode: '6001234500017', priceBuy: 3850, priceSell: 4500, tva: 0, vrac: false, threshold: 40),
  Product(id: 'riz25', name: 'Riz parfumé 25 kg', category: 'Céréales', unit: 'sac', barcode: '6001234500024', priceBuy: 15200, priceSell: 17500, tva: 0, vrac: false, threshold: 25),
  Product(id: 'hui1', name: 'Huile Dinor 1 L', category: 'Huiles', unit: 'bouteille', barcode: '6001987700013', priceBuy: 950, priceSell: 1200, tva: 0.18, vrac: false, threshold: 20),
  Product(id: 'hui5', name: 'Huile Dinor 5 L', category: 'Huiles', unit: 'bidon', barcode: '6001987700051', priceBuy: 5100, priceSell: 5800, tva: 0.18, vrac: false, threshold: 30),
  Product(id: 'suc', name: 'Sucre Princesse 1 kg', category: 'Épicerie', unit: 'paquet', barcode: '6003344500019', priceBuy: 720, priceSell: 900, tva: 0, vrac: false, threshold: 60),
  Product(id: 'att', name: 'Attiéké frais', category: 'Vrac', unit: 'kg', barcode: 'Vrac — balance', priceBuy: 450, priceSell: 600, tva: 0, vrac: true, threshold: 50),
  Product(id: 'lait', name: 'Lait Bonnet Rouge 400 g', category: 'Épicerie', unit: 'boîte', barcode: '6111022200048', priceBuy: 1950, priceSell: 2300, tva: 0.18, vrac: false, threshold: 50),
  Product(id: 'tom', name: 'Tomate concentrée 70 g', category: 'Épicerie', unit: 'boîte', barcode: '6009988770012', priceBuy: 150, priceSell: 200, tva: 0.18, vrac: false, threshold: 120),
  Product(id: 'mag', name: 'Cube Maggi ×50', category: 'Épicerie', unit: 'sachet', barcode: '6001112220015', priceBuy: 870, priceSell: 1100, tva: 0.18, vrac: false, threshold: 80),
  Product(id: 'sav', name: 'Savon Kabakrou', category: 'Hygiène', unit: 'barre', barcode: '6002225550012', priceBuy: 280, priceSell: 350, tva: 0.18, vrac: false, threshold: 100),
  Product(id: 'eau', name: 'Eau Awa 1,5 L ×6', category: 'Boissons', unit: 'pack', barcode: '6004446660011', priceBuy: 1800, priceSell: 2400, tva: 0.18, vrac: false, threshold: 40),
  Product(id: 'far', name: 'Farine de blé 1 kg', category: 'Épicerie', unit: 'paquet', barcode: '6007776660018', priceBuy: 620, priceSell: 800, tva: 0, vrac: false, threshold: 50),
  Product(id: 'sel', name: 'Sel iodé 1 kg', category: 'Épicerie', unit: 'paquet', barcode: '6005554440015', priceBuy: 220, priceSell: 300, tva: 0, vrac: false, threshold: 60),
  Product(id: 'pat', name: 'Pâtes Panzani 500 g', category: 'Épicerie', unit: 'paquet', barcode: '3038350201157', priceBuy: 520, priceSell: 700, tva: 0.18, vrac: false, threshold: 60),
  Product(id: 'hari', name: 'Haricot rouge (vrac)', category: 'Vrac', unit: 'kg', barcode: 'Vrac — balance', priceBuy: 700, priceSell: 950, tva: 0, vrac: true, threshold: 40),
  Product(id: 'gaz', name: 'Gaz butane 6 kg', category: 'Autres', unit: 'bouteille', barcode: '6008887770014', priceBuy: 2000, priceSell: 2500, tva: 0.18, vrac: false, threshold: 20),
];

/// storeId -> productId -> qty. Yopougon/Cocody/Adjamé/Abobo/Bouaké keep the
/// exact figures shown in the prototype's Stock screen (so the "rupture" /
/// "sous seuil" callouts stay consistent); the remaining stores get
/// plausible filler quantities.
final Map<String, Map<String, double>> stockByStore = {
  'yopougon': {'riz5': 184, 'riz25': 61, 'hui1': 96, 'hui5': 142, 'suc': 312, 'att': 88.5, 'lait': 204, 'tom': 640, 'mag': 301, 'sav': 418, 'eau': 210, 'far': 176, 'sel': 240, 'pat': 190, 'hari': 60, 'gaz': 48},
  'cocody': {'riz5': 246, 'riz25': 88, 'hui1': 118, 'hui5': 96, 'suc': 402, 'att': 42.0, 'lait': 265, 'tom': 712, 'mag': 344, 'sav': 366, 'eau': 188, 'far': 210, 'sel': 280, 'pat': 224, 'hari': 74, 'gaz': 52},
  'adjame': {'riz5': 92, 'riz25': 34, 'hui1': 14, 'hui5': 77, 'suc': 198, 'att': 130.0, 'lait': 121, 'tom': 0, 'mag': 288, 'sav': 502, 'eau': 96, 'far': 88, 'sel': 132, 'pat': 96, 'hari': 45, 'gaz': 22},
  'treichville': {'riz5': 150, 'riz25': 52, 'hui1': 60, 'hui5': 84, 'suc': 210, 'att': 54.0, 'lait': 140, 'tom': 380, 'mag': 190, 'sav': 240, 'eau': 120, 'far': 102, 'sel': 150, 'pat': 118, 'hari': 40, 'gaz': 26},
  'abobo': {'riz5': 0, 'riz25': 22, 'hui1': 31, 'hui5': 54, 'suc': 12, 'att': 61.5, 'lait': 96, 'tom': 288, 'mag': 0, 'sav': 274, 'eau': 8, 'far': 44, 'sel': 70, 'pat': 58, 'hari': 18, 'gaz': 6},
  'marcory': {'riz5': 118, 'riz25': 40, 'hui1': 47, 'hui5': 66, 'suc': 168, 'att': 36.0, 'lait': 112, 'tom': 300, 'mag': 150, 'sav': 190, 'eau': 92, 'far': 80, 'sel': 118, 'pat': 92, 'hari': 32, 'gaz': 20},
  'koumassi': {'riz5': 95, 'riz25': 30, 'hui1': 38, 'hui5': 52, 'suc': 130, 'att': 28.0, 'lait': 88, 'tom': 240, 'mag': 120, 'sav': 150, 'eau': 70, 'far': 62, 'sel': 90, 'pat': 70, 'hari': 24, 'gaz': 16},
  'bouake': {'riz5': 131, 'riz25': 45, 'hui1': 58, 'hui5': 63, 'suc': 221, 'att': 28.0, 'lait': 142, 'tom': 401, 'mag': 156, 'sav': 190, 'eau': 74, 'far': 98, 'sel': 132, 'pat': 104, 'hari': 36, 'gaz': 24},
  'daloa': {'riz5': 70, 'riz25': 28, 'hui1': 34, 'hui5': 40, 'suc': 120, 'att': 22.0, 'lait': 78, 'tom': 210, 'mag': 100, 'sav': 130, 'eau': 55, 'far': 54, 'sel': 78, 'pat': 62, 'hari': 20, 'gaz': 12},
  'sanpedro': {'riz5': 60, 'riz25': 24, 'hui1': 28, 'hui5': 34, 'suc': 96, 'att': 18.0, 'lait': 66, 'tom': 176, 'mag': 84, 'sav': 108, 'eau': 46, 'far': 46, 'sel': 64, 'pat': 52, 'hari': 16, 'gaz': 10},
};

const paymentMethods = ['Espèces', 'Orange Money', 'MTN MoMo', 'Wave', 'Ardoise client', 'Carte bancaire'];

/// Daily CA (M FCFA) for the last 30 days, used by the Rapports bar chart.
const caDays = <double>[
  11.2, 12.4, 13.1, 10.8, 14.6, 16.2, 9.4, 11.8, 12.9, 13.6, 12.1, 15.4, 17.1, 10.2,
  11.6, 13.3, 12.8, 14.1, 15.9, 16.8, 10.4, 11.1, 12.6, 13.9, 14.4, 15.2, 17.6, 12.2, 13.4, 14.86,
];

const suppliers = <Supplier>[
  Supplier(id: 'sania', name: 'SANIA Cie', categoryLabel: 'Huiles · Abidjan', contactName: 'M. Yao', phone: '27 21 75 44 10', reliabilityPct: 96, avgDelayDays: 4, encours: 2300000, paymentTerms: '30 jours'),
  Supplier(id: 'carredor', name: 'Groupe Carré d\'Or', categoryLabel: 'Céréales · Abidjan', contactName: 'Mme Diarra', phone: '27 21 30 88 02', reliabilityPct: 91, avgDelayDays: 6, encours: 8900000, paymentTerms: 'Virement'),
  Supplier(id: 'sucaf', name: 'SUCAF Côte d\'Ivoire', categoryLabel: 'Épicerie · Abidjan', contactName: 'M. Kra', phone: '27 21 40 12 55', reliabilityPct: 88, avgDelayDays: 5, encours: 4120000, paymentTerms: '45 jours'),
  Supplier(id: 'coopyakro', name: 'Coopérative Yamoussoukro', categoryLabel: 'Vrac · Yamoussoukro', contactName: 'M. Konan', phone: '05 04 12 66 90', reliabilityPct: 82, avgDelayDays: 3, encours: 0, paymentTerms: 'Comptant'),
  Supplier(id: 'awaboissons', name: 'Awa Boissons', categoryLabel: 'Boissons · Abidjan', contactName: 'Mme Aka', phone: '27 21 55 90 14', reliabilityPct: 93, avgDelayDays: 4, encours: 2214000, paymentTerms: 'Mobile Money'),
];

final purchaseOrders = <PurchaseOrder>[
  PurchaseOrder(id: 'cd1188', ref: 'CD-1188', supplierId: 'sania', expectedDate: DateTime(2026, 9, 5), linesCount: 5, amount: 2329000, paymentTerms: '30 jours', status: 'Confirmée'),
  PurchaseOrder(id: 'cd1187', ref: 'CD-1187', supplierId: 'carredor', expectedDate: DateTime(2026, 9, 8), linesCount: 12, amount: 8940500, paymentTerms: 'Virement', status: 'Confirmée'),
  PurchaseOrder(id: 'cd1186', ref: 'CD-1186', supplierId: 'sucaf', expectedDate: DateTime(2026, 9, 11), linesCount: 3, amount: 4120000, paymentTerms: '45 jours', status: 'En attente'),
  PurchaseOrder(id: 'cd1184', ref: 'CD-1184', supplierId: 'coopyakro', expectedDate: DateTime(2026, 9, 3), linesCount: 7, amount: 1682400, paymentTerms: 'Comptant', status: 'Retard 2 j'),
  PurchaseOrder(id: 'cd1181', ref: 'CD-1181', supplierId: 'awaboissons', expectedDate: DateTime(2026, 9, 4), linesCount: 4, amount: 2214000, paymentTerms: 'Mobile Money', status: 'Confirmée'),
];

final seedTransfers = <Transfer>[
  Transfer(id: 'tr2481', ref: 'TR-2481', originStoreId: 'cocody', destStoreId: 'abobo', productId: 'riz5', qty: 60, value: 243000, transport: 'Camionnette 01', status: TransferStatus.aValider, createdAt: DateTime(2026, 9, 2, 9, 10)),
  Transfer(id: 'tr2480', ref: 'TR-2480', originStoreId: 'yopougon', destStoreId: 'adjame', productId: 'hui1', qty: 24, value: 288000, transport: 'Camionnette 02', status: TransferStatus.enRoute, createdAt: DateTime(2026, 9, 1, 14, 0)),
  Transfer(id: 'tr2478', ref: 'TR-2478', originStoreId: 'yopougon', destStoreId: 'bouake', productId: 'riz5', qty: 30, value: 1862400, transport: 'Semi-remorque', status: TransferStatus.enRoute, createdAt: DateTime(2026, 8, 31, 8, 0)),
  Transfer(id: 'tr2475', ref: 'TR-2475', originStoreId: 'marcory', destStoreId: 'koumassi', productId: 'suc', qty: 200, value: 160000, transport: 'Tricycle', status: TransferStatus.recu, createdAt: DateTime(2026, 8, 30, 11, 0)),
  Transfer(id: 'tr2471', ref: 'TR-2471', originStoreId: 'yopougon', destStoreId: 'sanpedro', productId: 'lait', qty: 40, value: 974200, transport: 'Semi-remorque', status: TransferStatus.recu, createdAt: DateTime(2026, 8, 29, 9, 30)),
  Transfer(id: 'tr2468', ref: 'TR-2468', originStoreId: 'daloa', destStoreId: 'bouake', productId: 'far', qty: 150, value: 97500, transport: 'Car de ligne', status: TransferStatus.ecart, createdAt: DateTime(2026, 8, 28, 16, 0)),
];

final seedReceptions = (
  Reception(id: 'bl90112', ref: 'BL-90112', supplierId: 'sania', storeId: 'yopougon', date: DateTime(2026, 9, 2), status: 'Écart'),
  <ReceptionLine>[
    ReceptionLine(id: 'rl1', receptionId: 'bl90112', productId: 'hui1', lot: 'SA-2609', expiry: '08/2027', expectedQty: 120, receivedQty: 114, buyPrice: 11400),
    ReceptionLine(id: 'rl2', receptionId: 'bl90112', productId: 'hui5', lot: 'SA-2611', expiry: '08/2027', expectedQty: 80, receivedQty: 80, buyPrice: 5100),
    ReceptionLine(id: 'rl3', receptionId: 'bl90112', productId: 'sav', lot: 'KB-118', expiry: null, expectedQty: 400, receivedQty: 400, buyPrice: 280),
    ReceptionLine(id: 'rl4', receptionId: 'bl90112', productId: 'tom', lot: 'TC-4402', expiry: '03/2028', expectedQty: 1200, receivedQty: 1200, buyPrice: 150),
    ReceptionLine(id: 'rl5', receptionId: 'bl90112', productId: 'mag', lot: 'MG-771', expiry: '11/2027', expectedQty: 300, receivedQty: 300, buyPrice: 870),
  ],
);

final seedUsers = <UserAccount>[
  UserAccount(id: 'u1', name: 'Kouassi Aboa', role: 'Direction', storeId: null, device: 'Windows', lastActive: DateTime(2026, 9, 2, 11, 40), status: 'Actif', pin: '5031'),
  UserAccount(id: 'u2', name: 'Awa Traoré', role: 'Gérante', storeId: 'cocody', device: 'Windows', lastActive: DateTime(2026, 9, 2, 11, 36), status: 'Actif', pin: '2575'),
  UserAccount(id: 'u3', name: 'Ismaël Bakayoko', role: 'Gérant', storeId: 'abobo', device: 'Android', lastActive: DateTime(2026, 9, 2, 11, 21), status: 'Hors ligne', pin: '1292'),
  UserAccount(id: 'u4', name: 'Fatou Coulibaly', role: 'Caissière', storeId: 'yopougon', device: 'Windows · poste 03', lastActive: DateTime(2026, 9, 2, 11, 41), status: 'En caisse', pin: '1055'),
  UserAccount(id: 'u5', name: 'Serge Gbagbo', role: 'Magasinier', storeId: 'adjame', device: 'Android · douchette', lastActive: DateTime(2026, 9, 2, 11, 38), status: 'Actif', pin: '5347'),
  UserAccount(id: 'u6', name: 'Marie Kone', role: 'Caissière', storeId: 'bouake', device: 'Android', lastActive: DateTime(2026, 9, 1, 19, 40), status: 'Inactif', pin: '7878'),
  UserAccount(id: 'u7', name: 'Ali Ouattara', role: 'Comptable', storeId: null, device: 'Windows', lastActive: DateTime(2026, 9, 2, 10, 54), status: 'Actif', pin: '8884'),
];

const creditAccounts = <CreditAccount>[
  CreditAccount(id: 'c1', customerName: 'Mme Kouadio', storeId: 'yopougon', balance: 12400, ceiling: 25000),
  CreditAccount(id: 'c2', customerName: 'M. Diabaté', storeId: 'cocody', balance: 8600, ceiling: 20000),
  CreditAccount(id: 'c3', customerName: 'Mme Yao', storeId: 'adjame', balance: 21000, ceiling: 25000),
];

final seedExpenses = <Expense>[
  Expense(id: 'e1', storeId: 'yopougon', label: 'Loyer septembre', category: 'Loyer', amount: 450000, date: DateTime(2026, 9, 1)),
  Expense(id: 'e2', storeId: 'cocody', label: 'Facture CIE', category: 'Électricité', amount: 68000, date: DateTime(2026, 9, 1)),
  Expense(id: 'e3', storeId: 'yopougon', label: 'Carburant livraison', category: 'Transport', amount: 25000, date: DateTime(2026, 9, 2)),
  Expense(id: 'e4', storeId: 'abobo', label: 'Réparation vitrine', category: 'Entretien', amount: 40000, date: DateTime(2026, 8, 30)),
  Expense(id: 'e5', storeId: 'adjame', label: 'Fournitures bureau', category: 'Autre', amount: 15500, date: DateTime(2026, 9, 2)),
];

/// Relative daily activity weight per store, taken from the "CA jour" column
/// on the prototype's Dashboard table (they happen to sum to its 14 862 350
/// FCFA headline, so this keeps the two consistent).
const _storeWeight = <String, int>{
  'yopougon': 2145600,
  'cocody': 2908100,
  'adjame': 1976450,
  'treichville': 1204700,
  'abobo': 1588900,
  'marcory': 1342000,
  'koumassi': 961250,
  'bouake': 1455300,
  'daloa': 704800,
  'sanpedro': 575250,
};

/// Products more likely to end up in a basket, roughly matching the
/// "Top produits" ranking on the prototype's dashboard.
const _productWeight = <String, int>{
  'riz5': 6, 'hui1': 5, 'suc': 4, 'att': 4, 'lait': 3,
};

const _paymentWeights = <(String, int)>[
  ('Espèces', 48), ('Orange Money', 24), ('Wave', 15), ('MTN MoMo', 7), ('Ardoise client', 6),
];

String _pickWeighted(Random rng, List<(String, int)> weighted) {
  final total = weighted.fold<int>(0, (a, e) => a + e.$2);
  var roll = rng.nextInt(total);
  for (final (label, w) in weighted) {
    if (roll < w) return label;
    roll -= w;
  }
  return weighted.last.$1;
}

Product _pickProduct(Random rng) {
  final weighted = [for (final p in products) (p.id, _productWeight[p.id] ?? 1)];
  final id = _pickWeighted(rng, weighted);
  return products.firstWhere((p) => p.id == id);
}

/// How many of the most recent days in [caDays] to seed history for.
/// Firestore reads/writes aren't free, so this build seeds a shorter
/// window than the original local-SQLite version did (30 days) while
/// keeping the same daily-activity shape.
const demoHistoryDays = 14;

/// Generates a modest, deterministic history of sales tickets spread over
/// the last [demoHistoryDays] days and across all 10 stores, so the
/// Dashboard and Rapports screens have real (if smaller-scale than the
/// original mockup) numbers to compute from the moment the app first
/// launches. Each line document carries denormalized `category`,
/// `store_id`, `created_at` and `pay_method` copied from its parent ticket
/// so Firestore's `collectionGroup('lines')` queries (used for the
/// dashboard/reports aggregations) don't need a join back to the ticket.
(List<Ticket>, List<Map<String, Object?>>) buildDemoSales(DateTime now) {
  final rng = Random(20260902);
  final recentDays = caDays.sublist(caDays.length - demoHistoryDays);
  final tickets = <Ticket>[];
  final lines = <Map<String, Object?>>[];
  final totalWeight = _storeWeight.values.fold<int>(0, (a, b) => a + b);
  final avgCaDay = recentDays.reduce((a, b) => a + b) / recentDays.length;
  var ticketNo = 1000;

  for (var i = 0; i < recentDays.length; i++) {
    final daysAgo = recentDays.length - 1 - i;
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
    final dayFactor = recentDays[i] / avgCaDay;

    for (final store in stores) {
      final weight = (_storeWeight[store.id] ?? 500000) / totalWeight;
      final numTickets = max(2, (weight * 14 * dayFactor).round());
      for (var n = 0; n < numTickets; n++) {
        final peak = rng.nextDouble() < 0.6;
        final hour = peak ? (11 + rng.nextInt(3) + (rng.nextBool() ? 6 : 0)) : (7 + rng.nextInt(15));
        final createdAt = date.add(Duration(hours: hour.clamp(7, 21), minutes: rng.nextInt(60)));
        final payMethod = _pickWeighted(rng, _paymentWeights);

        final lineCount = 1 + rng.nextInt(4);
        var ttc = 0;
        var tva = 0;
        ticketNo++;
        final ticketId = 'seed-$ticketNo';
        for (var l = 0; l < lineCount; l++) {
          final p = _pickProduct(rng);
          final qty = p.vrac ? (0.5 + rng.nextInt(4) * 0.5) : (1 + rng.nextInt(3)).toDouble();
          final total = (p.priceSell * qty).round();
          ttc += total;
          tva += total - (total / (1 + p.tva)).round();
          lines.add({
            'id': '$ticketId-$l',
            'ticket_id': ticketId,
            'product_id': p.id,
            'qty': qty,
            'unit_price': p.priceSell,
            'total': total,
            'category': p.category,
            'store_id': store.id,
            'created_at': createdAt.toIso8601String(),
            'pay_method': payMethod,
          });
        }
        tickets.add(Ticket(
          id: ticketId,
          storeId: store.id,
          ticketNo: ticketNo,
          createdAt: createdAt,
          payMethod: payMethod,
          totalTtc: ttc,
          totalHt: ttc - tva,
          tva: tva,
          synced: true,
        ));
      }
    }
  }
  return (tickets, lines);
}
