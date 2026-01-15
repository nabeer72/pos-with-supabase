import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  var salesSummary = {'totalAmount': 0.0, 'totalCount': 0}.obs;
  var favoriteProducts = <String, dynamic>{}.obs; // Actually list of Product, but keeping consistent structure if needed, or better List<Product>
  // Let's use List since it's products
  var favProducts = <dynamic>[].obs; 
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final summary = await _dbHelper.getSalesSummary(adminId: authController.adminId);
      salesSummary.value = {
        'totalAmount': (summary['totalAmount'] as num?)?.toDouble() ?? 0.0,
        'totalCount': (summary['totalCount'] as num?)?.toInt() ?? 0,
      };
      
      final products = await _dbHelper.getFavoriteProducts(adminId: authController.adminId);
      favProducts.value = products;
      
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
