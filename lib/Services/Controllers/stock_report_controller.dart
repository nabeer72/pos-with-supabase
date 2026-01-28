import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/receipt_service.dart';

class StockReportController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReceiptService _receiptService = ReceiptService();
  
  final stockItems = <Product>[].obs;
  final isLoading = true.obs;
  final storeName = 'My Store'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      
      // Fetch store name from receipt settings
      final receiptSettings = await _receiptService.getReceiptSettings();
      storeName.value = receiptSettings['store_name'] ?? 'My Store';
      
      final items = await _dbHelper.getProducts(adminId: authController.adminId);
      
      // Sort items by quantity (ascending) so low stock items appear first
      items.sort((a, b) => a.quantity.compareTo(b.quantity));
      
      stockItems.assignAll(items);
    } catch (e) {
      print('Error fetching stock data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
