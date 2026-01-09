class Sale {
  final int? id;
  final DateTime saleDate;
  final double totalAmount;
  final int? customerId;
  final String? supabaseId;
  final bool isSynced;

  Sale({
    this.id,
    required this.saleDate,
    required this.totalAmount,
    this.customerId,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleDate': saleDate.toIso8601String(),
      'totalAmount': totalAmount,
      'customerId': customerId,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      saleDate: DateTime.parse(map['saleDate']),
      totalAmount: map['totalAmount'],
      customerId: map['customerId'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
