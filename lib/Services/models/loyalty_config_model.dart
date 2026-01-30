class LoyaltyTier {
  final int? id;
  final String tierName;
  final double spendRangeMin;
  final double spendRangeMax;
  final double discountPercentage;
  final String? adminId;
  final String? supabaseId;
  final bool isSynced;

  LoyaltyTier({
    this.id,
    required this.tierName,
    this.spendRangeMin = 0.0,
    this.spendRangeMax = 0.0,
    this.discountPercentage = 0.0,
    this.adminId,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tier_name': tierName,
      'spend_range_min': spendRangeMin,
      'spend_range_max': spendRangeMax,
      'discount_percentage': discountPercentage,
      'admin_id': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LoyaltyTier.fromMap(Map<String, dynamic> map) {
    return LoyaltyTier(
      id: map['id'],
      tierName: map['tier_name'],
      spendRangeMin: (map['spend_range_min'] as num?)?.toDouble() ?? 0.0,
      spendRangeMax: (map['spend_range_max'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      adminId: map['admin_id'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}

class LoyaltyRule {
  final int? id;
  final double pointsPerCurrencyUnit;
  final double cashbackPercentage;
  final int pointsExpiryMonths;
  final double redemptionValuePerPoint;
  final String? adminId;
  final String? supabaseId;
  final bool isSynced;

  LoyaltyRule({
    this.id,
    this.pointsPerCurrencyUnit = 1.0,
    this.cashbackPercentage = 0.0,
    this.pointsExpiryMonths = 12,
    this.redemptionValuePerPoint = 0.5,
    this.adminId,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points_per_currency_unit': pointsPerCurrencyUnit,
      'cashback_percentage': cashbackPercentage,
      'points_expiry_months': pointsExpiryMonths,
      'redemption_value_per_point': redemptionValuePerPoint,
      'admin_id': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LoyaltyRule.fromMap(Map<String, dynamic> map) {
    return LoyaltyRule(
      id: map['id'],
      pointsPerCurrencyUnit: (map['points_per_currency_unit'] as num?)?.toDouble() ?? 1.0,
      cashbackPercentage: (map['cashback_percentage'] as num?)?.toDouble() ?? 0.0,
      pointsExpiryMonths: map['points_expiry_months'] ?? 12,
      redemptionValuePerPoint: (map['redemption_value_per_point'] as num?)?.toDouble() ?? 0.5,
      adminId: map['admin_id'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
