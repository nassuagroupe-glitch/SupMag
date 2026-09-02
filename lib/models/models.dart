/// Plain data models for SupMag. Each has fromMap/toMap for the Firestore
/// layer in lib/data/firestore_repository.dart.
library;

class Store {
  final String id;
  final String name;
  final String city;

  const Store({required this.id, required this.name, required this.city});

  factory Store.fromMap(Map<String, Object?> m) =>
      Store(id: m['id'] as String, name: m['name'] as String, city: m['city'] as String);

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'city': city};
}

class Product {
  final String id;
  final String name;
  final String category;
  final String unit;
  final String barcode;
  final int priceBuy;
  final int priceSell;
  final double tva; // 0 or 0.18
  final bool vrac; // sold loose / by weight
  final int threshold; // low-stock threshold, store-agnostic default

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.barcode,
    required this.priceBuy,
    required this.priceSell,
    required this.tva,
    required this.vrac,
    required this.threshold,
  });

  double get marginPct => priceBuy == 0 ? 0 : (priceSell - priceBuy) / priceBuy * 100;

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        unit: m['unit'] as String,
        barcode: m['barcode'] as String,
        priceBuy: m['price_buy'] as int,
        priceSell: m['price_sell'] as int,
        tva: (m['tva'] as num).toDouble(),
        vrac: (m['vrac'] as int) == 1,
        threshold: m['threshold'] as int,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'barcode': barcode,
        'price_buy': priceBuy,
        'price_sell': priceSell,
        'tva': tva,
        'vrac': vrac ? 1 : 0,
        'threshold': threshold,
      };
}

class StockLevel {
  final String storeId;
  final String productId;
  final double qty;

  const StockLevel({required this.storeId, required this.productId, required this.qty});

  factory StockLevel.fromMap(Map<String, Object?> m) => StockLevel(
        storeId: m['store_id'] as String,
        productId: m['product_id'] as String,
        qty: (m['qty'] as num).toDouble(),
      );

  Map<String, Object?> toMap() => {'store_id': storeId, 'product_id': productId, 'qty': qty};
}

class CartLine {
  final Product product;
  double qty;
  CartLine({required this.product, required this.qty});

  int get total => (product.priceSell * qty).round();
  int get ht => (total / (1 + product.tva)).round();
  int get tax => total - ht;
}

class Ticket {
  final String id;
  final String storeId;
  final int ticketNo;
  final DateTime createdAt;
  final String payMethod;
  final int totalTtc;
  final int totalHt;
  final int tva;
  final bool synced;

  const Ticket({
    required this.id,
    required this.storeId,
    required this.ticketNo,
    required this.createdAt,
    required this.payMethod,
    required this.totalTtc,
    required this.totalHt,
    required this.tva,
    required this.synced,
  });

  factory Ticket.fromMap(Map<String, Object?> m) => Ticket(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        ticketNo: m['ticket_no'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        payMethod: m['pay_method'] as String,
        totalTtc: m['total_ttc'] as int,
        totalHt: m['total_ht'] as int,
        tva: m['tva'] as int,
        synced: (m['synced'] as int) == 1,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'store_id': storeId,
        'ticket_no': ticketNo,
        'created_at': createdAt.toIso8601String(),
        'pay_method': payMethod,
        'total_ttc': totalTtc,
        'total_ht': totalHt,
        'tva': tva,
        'synced': synced ? 1 : 0,
      };
}

enum TransferStatus { aValider, enRoute, recu, ecart }

extension TransferStatusLabel on TransferStatus {
  String get label => switch (this) {
        TransferStatus.aValider => 'À valider',
        TransferStatus.enRoute => 'En route',
        TransferStatus.recu => 'Reçu',
        TransferStatus.ecart => 'Écart',
      };
}

class Transfer {
  final String id;
  final String ref;
  final String originStoreId;
  final String destStoreId;
  final String productId;
  final double qty;
  final int value;
  final String transport;
  final TransferStatus status;
  final DateTime createdAt;

  const Transfer({
    required this.id,
    required this.ref,
    required this.originStoreId,
    required this.destStoreId,
    required this.productId,
    required this.qty,
    required this.value,
    required this.transport,
    required this.status,
    required this.createdAt,
  });

  factory Transfer.fromMap(Map<String, Object?> m) => Transfer(
        id: m['id'] as String,
        ref: m['ref'] as String,
        originStoreId: m['origin_store_id'] as String,
        destStoreId: m['dest_store_id'] as String,
        productId: m['product_id'] as String,
        qty: (m['qty'] as num).toDouble(),
        value: m['value'] as int,
        transport: m['transport'] as String,
        status: TransferStatus.values.byName(m['status'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'ref': ref,
        'origin_store_id': originStoreId,
        'dest_store_id': destStoreId,
        'product_id': productId,
        'qty': qty,
        'value': value,
        'transport': transport,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}

class Supplier {
  final String id;
  final String name;
  final String categoryLabel;
  final String contactName;
  final String phone;
  final double reliabilityPct;
  final int avgDelayDays;
  final int encours;
  final String paymentTerms;

  const Supplier({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.contactName,
    required this.phone,
    required this.reliabilityPct,
    required this.avgDelayDays,
    required this.encours,
    required this.paymentTerms,
  });

  factory Supplier.fromMap(Map<String, Object?> m) => Supplier(
        id: m['id'] as String,
        name: m['name'] as String,
        categoryLabel: m['category_label'] as String,
        contactName: m['contact_name'] as String,
        phone: m['phone'] as String,
        reliabilityPct: (m['reliability_pct'] as num).toDouble(),
        avgDelayDays: m['avg_delay_days'] as int,
        encours: m['encours'] as int,
        paymentTerms: m['payment_terms'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category_label': categoryLabel,
        'contact_name': contactName,
        'phone': phone,
        'reliability_pct': reliabilityPct,
        'avg_delay_days': avgDelayDays,
        'encours': encours,
        'payment_terms': paymentTerms,
      };
}

class PurchaseOrder {
  final String id;
  final String ref;
  final String supplierId;
  final DateTime expectedDate;
  final int linesCount;
  final int amount;
  final String paymentTerms;
  final String status;

  const PurchaseOrder({
    required this.id,
    required this.ref,
    required this.supplierId,
    required this.expectedDate,
    required this.linesCount,
    required this.amount,
    required this.paymentTerms,
    required this.status,
  });

  factory PurchaseOrder.fromMap(Map<String, Object?> m) => PurchaseOrder(
        id: m['id'] as String,
        ref: m['ref'] as String,
        supplierId: m['supplier_id'] as String,
        expectedDate: DateTime.parse(m['expected_date'] as String),
        linesCount: m['lines_count'] as int,
        amount: m['amount'] as int,
        paymentTerms: m['payment_terms'] as String,
        status: m['status'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'ref': ref,
        'supplier_id': supplierId,
        'expected_date': expectedDate.toIso8601String(),
        'lines_count': linesCount,
        'amount': amount,
        'payment_terms': paymentTerms,
        'status': status,
      };
}

class ReceptionLine {
  final String id;
  final String receptionId;
  final String productId;
  final String lot;
  final String? expiry;
  final double expectedQty;
  final double receivedQty;
  final int buyPrice;

  const ReceptionLine({
    required this.id,
    required this.receptionId,
    required this.productId,
    required this.lot,
    required this.expiry,
    required this.expectedQty,
    required this.receivedQty,
    required this.buyPrice,
  });

  double get gap => receivedQty - expectedQty;
  int get amount => (buyPrice * receivedQty).round();

  factory ReceptionLine.fromMap(Map<String, Object?> m) => ReceptionLine(
        id: m['id'] as String,
        receptionId: m['reception_id'] as String,
        productId: m['product_id'] as String,
        lot: m['lot'] as String,
        expiry: m['expiry'] as String?,
        expectedQty: (m['expected_qty'] as num).toDouble(),
        receivedQty: (m['received_qty'] as num).toDouble(),
        buyPrice: m['buy_price'] as int,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'reception_id': receptionId,
        'product_id': productId,
        'lot': lot,
        'expiry': expiry,
        'expected_qty': expectedQty,
        'received_qty': receivedQty,
        'buy_price': buyPrice,
      };
}

class Reception {
  final String id;
  final String ref;
  final String supplierId;
  final String storeId;
  final DateTime date;
  final String status;

  const Reception({
    required this.id,
    required this.ref,
    required this.supplierId,
    required this.storeId,
    required this.date,
    required this.status,
  });

  factory Reception.fromMap(Map<String, Object?> m) => Reception(
        id: m['id'] as String,
        ref: m['ref'] as String,
        supplierId: m['supplier_id'] as String,
        storeId: m['store_id'] as String,
        date: DateTime.parse(m['date'] as String),
        status: m['status'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'ref': ref,
        'supplier_id': supplierId,
        'store_id': storeId,
        'date': date.toIso8601String(),
        'status': status,
      };
}

class UserAccount {
  final String id;
  final String name;
  final String role; // Direction, Gérant(e), Caissier(ère), Magasinier, Comptable
  final String? storeId; // null = tous / siège
  final String device;
  final DateTime lastActive;
  final String status; // Actif, En caisse, Hors ligne, Inactif

  const UserAccount({
    required this.id,
    required this.name,
    required this.role,
    required this.storeId,
    required this.device,
    required this.lastActive,
    required this.status,
  });

  factory UserAccount.fromMap(Map<String, Object?> m) => UserAccount(
        id: m['id'] as String,
        name: m['name'] as String,
        role: m['role'] as String,
        storeId: m['store_id'] as String?,
        device: m['device'] as String,
        lastActive: DateTime.parse(m['last_active'] as String),
        status: m['status'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'store_id': storeId,
        'device': device,
        'last_active': lastActive.toIso8601String(),
        'status': status,
      };
}

class CreditAccount {
  final String id;
  final String customerName;
  final String storeId;
  final int balance;
  final int ceiling;

  const CreditAccount({
    required this.id,
    required this.customerName,
    required this.storeId,
    required this.balance,
    required this.ceiling,
  });

  factory CreditAccount.fromMap(Map<String, Object?> m) => CreditAccount(
        id: m['id'] as String,
        customerName: m['customer_name'] as String,
        storeId: m['store_id'] as String,
        balance: m['balance'] as int,
        ceiling: m['ceiling'] as int,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'customer_name': customerName,
        'store_id': storeId,
        'balance': balance,
        'ceiling': ceiling,
      };
}
