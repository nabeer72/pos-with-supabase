import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:get/get.dart';

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  String? _currentAdminId;

  void setCurrentAdminId(String adminId) {
    _currentAdminId = adminId;
  }

  Future<Map<String, String>> getReceiptSettings() async {
    final adminId = _currentAdminId ?? Get.find<AuthController>().adminId;
    if (adminId == null) return {};

    final storeName = await _dbHelper.getSetting('store_name', adminId: adminId) ?? 'My Store';
    final storeAddress = await _dbHelper.getSetting('store_address', adminId: adminId) ?? '';
    final storePhone = await _dbHelper.getSetting('store_phone', adminId: adminId) ?? '';
    final receiptFooter = await _dbHelper.getSetting('receipt_footer', adminId: adminId) ?? 'Thank you for your business!';

    return {
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'receipt_footer': receiptFooter,
    };
  }

  Future<void> updateReceiptSettings(Map<String, String> settings) async {
    final authController = Get.find<AuthController>();
    final adminId = authController.adminId;
    if (adminId == null) return;

    for (var entry in settings.entries) {
      await _dbHelper.updateSetting(entry.key, entry.value, adminId: adminId);
    }
    
    // Trigger sync
    SupabaseService().syncData();
  }
}
