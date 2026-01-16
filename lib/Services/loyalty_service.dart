import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/loyalty_account_model.dart';
import 'package:pos/Services/models/loyalty_transaction_model.dart';
import 'package:pos/Services/models/loyalty_config_model.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';

class LoyaltyService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  static LoyaltyService get to => Get.find();

  // Rules and Tiers cached
  LoyaltyRule? _currentRules;
  List<LoyaltyTier>? _currentTiers;

  Future<void> init() async {
    final adminId = Get.find<AuthController>().adminId;
    if (adminId != null) {
      await loadConfig(adminId);
    }
  }

  Future<void> loadConfig(String adminId) async {
    final rulesMap = await _dbHelper.getLoyaltyRules(adminId);
    if (rulesMap != null) {
      _currentRules = LoyaltyRule.fromMap(rulesMap);
    } else {
      // Default rules
      _currentRules = LoyaltyRule(adminId: adminId);
      await _dbHelper.updateLoyaltyRules(_currentRules!.toMap());
    }

    final tiersMap = await _dbHelper.getLoyaltyTiers(adminId);
    if (tiersMap.isNotEmpty) {
      _currentTiers = tiersMap.map((m) => LoyaltyTier.fromMap(m)).toList();
    } else {
      // Seed default tiers
      _currentTiers = [
        LoyaltyTier(tierName: 'Bronze', spendRangeMin: 0, spendRangeMax: 1000, discountPercentage: 0, adminId: adminId),
        LoyaltyTier(tierName: 'Silver', spendRangeMin: 1001, spendRangeMax: 5000, discountPercentage: 5, adminId: adminId),
        LoyaltyTier(tierName: 'Gold', spendRangeMin: 5001, spendRangeMax: 15000, discountPercentage: 10, adminId: adminId),
        LoyaltyTier(tierName: 'Platinum', spendRangeMin: 15001, spendRangeMax: double.infinity, discountPercentage: 15, adminId: adminId),
      ];
      for (var tier in _currentTiers!) {
        await _dbHelper.insertLoyaltyTier(tier.toMap());
      }
    }
  }

  Future<LoyaltyAccount> getAccount(int customerId) async {
    final adminId = Get.find<AuthController>().adminId;
    final map = await _dbHelper.getLoyaltyAccount(customerId);
    if (map != null) {
      return LoyaltyAccount.fromMap(map);
    }
    // Create new account
    final newAccount = LoyaltyAccount(customerId: customerId, adminId: adminId);
    int id = await _dbHelper.insertLoyaltyAccount(newAccount.toMap());
    
    // Trigger sync
    SupabaseService().syncData();
    
    return LoyaltyAccount(
      id: id,
      customerId: customerId,
      adminId: adminId,
    );
  }

  double calculatePoints(double amount) {
    if (_currentRules == null) return 0;
    return amount * _currentRules!.pointsPerCurrencyUnit;
  }

  double calculateCashback(double amount) {
    if (_currentRules == null) return 0;
    return (amount * _currentRules!.cashbackPercentage) / 100;
  }

  LoyaltyTier getTierForSpend(double spend) {
    if (_currentTiers == null || _currentTiers!.isEmpty) {
      return LoyaltyTier(tierName: 'Standard', discountPercentage: 0);
    }
    
    return _currentTiers!.firstWhere(
      (t) => spend >= t.spendRangeMin && spend <= t.spendRangeMax,
      orElse: () => _currentTiers!.first,
    );
  }

  Future<void> processSaleLoyalty({
    required int customerId,
    required double billAmount,
    int? invoiceId,
    double pointsRedeemed = 0,
    double cashbackUsed = 0,
  }) async {
    final adminId = Get.find<AuthController>().adminId;
    final account = await getAccount(customerId);
    
    double pointsEarned = calculatePoints(billAmount);
    double cashbackEarned = calculateCashback(billAmount);
    
    // 1. Record Transaction
    final transaction = LoyaltyTransaction(
      invoiceId: invoiceId,
      customerId: customerId,
      pointsEarned: pointsEarned,
      pointsRedeemed: pointsRedeemed,
      cashbackEarned: cashbackEarned,
      cashbackUsed: cashbackUsed,
      createdAt: DateTime.now().toIso8601String(),
      adminId: adminId,
    );
    await _dbHelper.insertLoyaltyTransaction(transaction.toMap());
    
    // 2. Update Account
    double newLifetimeSpend = account.lifetimeSpend + billAmount;
    final newTier = getTierForSpend(newLifetimeSpend);
    
    final updatedAccount = LoyaltyAccount(
      id: account.id,
      customerId: customerId,
      totalPoints: account.totalPoints + pointsEarned - pointsRedeemed,
      cashbackBalance: account.cashbackBalance + cashbackEarned - cashbackUsed,
      currentTier: newTier.tierName,
      lifetimeSpend: newLifetimeSpend,
      adminId: adminId,
      isSynced: false,
    );
    
    await _dbHelper.updateLoyaltyAccount(updatedAccount.toMap());
    
    // Trigger sync
    SupabaseService().syncData();
  }

  LoyaltyRule? get currentRules => _currentRules;
  List<LoyaltyTier>? get currentTiers => _currentTiers;
}
