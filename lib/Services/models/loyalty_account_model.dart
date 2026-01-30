class LoyaltyAccount {
  final int? id;
  final int customerId;
  final double totalPoints;
  final double cashbackBalance;
  final double lifetimeSpend;
  final String? adminId;
  final String? supabaseId;
  final bool isSynced;

  LoyaltyAccount({
    this.id,
    required this.customerId,
    this.totalPoints = 0.0,
    this.cashbackBalance = 0.0,
    this.lifetimeSpend = 0.0,
    this.adminId,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'total_points': totalPoints,
      'cashback_balance': cashbackBalance,
      'lifetime_spend': lifetimeSpend,
      'admin_id': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LoyaltyAccount.fromMap(Map<String, dynamic> map) {
    return LoyaltyAccount(
      id: map['id'],
      customerId: map['customer_id'],
      totalPoints: (map['total_points'] as num?)?.toDouble() ?? 0.0,
      cashbackBalance: (map['cashback_balance'] as num?)?.toDouble() ?? 0.0,
      lifetimeSpend: (map['lifetime_spend'] as num?)?.toDouble() ?? 0.0,
      adminId: map['admin_id'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
