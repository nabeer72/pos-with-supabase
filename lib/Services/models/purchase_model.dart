
class PurchaseOrder {
  int? id;
  int? supplierId;
  String orderDate;
  String? expectedDate;
  String status; // 'Draft', 'Ordered', 'Partial', 'Received', 'Cancelled'
  double totalAmount;
  String? notes;
  String? adminId;
  String? supabaseId;
  int isSynced;
  List<PurchaseItem> items; 
  String? supplierName; // For UI convenience

  PurchaseOrder({
    this.id,
    this.supplierId,
    required this.orderDate,
    this.expectedDate,
    this.status = 'Draft',
    this.totalAmount = 0.0,
    this.notes,
    this.adminId,
    this.supabaseId,
    this.isSynced = 0,
    this.items = const [],
    this.supplierName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'orderDate': orderDate,
      'expectedDate': expectedDate,
      'status': status,
      'totalAmount': totalAmount,
      'notes': notes,
      'adminId': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map, {List<PurchaseItem>? items, String? supplierName}) {
    return PurchaseOrder(
      id: map['id'],
      supplierId: map['supplierId'],
      orderDate: map['orderDate'],
      expectedDate: map['expectedDate'],
      status: map['status'] ?? 'Draft',
      totalAmount: map['totalAmount'] ?? 0.0,
      notes: map['notes'],
      adminId: map['adminId'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] ?? 0,
      items: items ?? [],
      supplierName: supplierName,
    );
  }
}

class PurchaseItem {
  int? id;
  int? purchaseId;
  int productId;
  int quantity;
  int receivedQuantity;
  double unitCost;
  String? adminId;
  String? supabaseId;
  int isSynced;
  String? productName; // For UI convenience

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.productId,
    this.quantity = 0,
    this.receivedQuantity = 0,
    this.unitCost = 0.0,
    this.adminId,
    this.supabaseId,
    this.isSynced = 0,
    this.productName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'quantity': quantity,
      'receivedQuantity': receivedQuantity,
      'unitCost': unitCost,
      'adminId': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map, {String? productName}) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchaseId'],
      productId: map['productId'],
      quantity: map['quantity'] ?? 0,
      receivedQuantity: map['receivedQuantity'] ?? 0,
      unitCost: map['unitCost'] ?? 0.0,
      adminId: map['adminId'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] ?? 0,
      productName: productName,
    );
  }
}
