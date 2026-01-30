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

  // Rules cached
  LoyaltyRule? _currentRules;

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
    
    final updatedAccount = LoyaltyAccount(
      id: account.id,
      customerId: customerId,
      totalPoints: account.totalPoints + pointsEarned - pointsRedeemed,
      cashbackBalance: account.cashbackBalance + cashbackEarned - cashbackUsed,
      lifetimeSpend: newLifetimeSpend,
      adminId: adminId,
      isSynced: false,
    );
    
    await _dbHelper.updateLoyaltyAccount(updatedAccount.toMap());
    
    // Trigger sync
    SupabaseService().syncData();
  }

  LoyaltyRule? get currentRules => _currentRules;
}
