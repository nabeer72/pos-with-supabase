class LoyaltyTransaction {
  final int? id;
  final int? invoiceId;
  final int customerId;
  final double pointsEarned;
  final double pointsRedeemed;
  final double cashbackEarned;
  final double cashbackUsed;
  final String createdAt;
  final String? adminId;
  final String? supabaseId;
  final bool isSynced;

  LoyaltyTransaction({
    this.id,
    this.invoiceId,
    required this.customerId,
    this.pointsEarned = 0.0,
    this.pointsRedeemed = 0.0,
    this.cashbackEarned = 0.0,
    this.cashbackUsed = 0.0,
    required this.createdAt,
    this.adminId,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'customer_id': customerId,
      'points_earned': pointsEarned,
      'points_redeemed': pointsRedeemed,
      'cashback_earned': cashbackEarned,
      'cashback_used': cashbackUsed,
      'created_at': createdAt,
      'admin_id': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransaction(
      id: map['id'],
      invoiceId: map['invoice_id'],
      customerId: map['customer_id'],
      pointsEarned: (map['points_earned'] as num?)?.toDouble() ?? 0.0,
      pointsRedeemed: (map['points_redeemed'] as num?)?.toDouble() ?? 0.0,
      cashbackEarned: (map['cashback_earned'] as num?)?.toDouble() ?? 0.0,
      cashbackUsed: (map['cashback_used'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'],
      adminId: map['admin_id'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
