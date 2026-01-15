class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final String? supabaseId;
  final bool isSynced;
  final String? adminId; // Added for multi-tenancy

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.supabaseId,
    this.isSynced = false,
    this.adminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
      'adminId': adminId,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'],
      productId: map['productId'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
      adminId: map['adminId'],
    );
  }
}
