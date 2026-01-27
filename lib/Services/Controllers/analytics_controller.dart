import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class AnalyticsController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  final isLoading = true.obs;
  
  final totalSales = 0.0.obs;
  final totalExpenses = 0.0.obs;
  final netProfit = 0.0.obs;
  
  final salesByCategory = <Map<String, dynamic>>[].obs;
  final topProducts = <Map<String, dynamic>>[].obs;
  final monthlyStats = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final adminId = authController.adminId;

      // Fetch basic summary
      final summary = await _dbHelper.getSalesSummary(adminId: adminId);
      totalSales.value = (summary['totalAmount'] as num?)?.toDouble() ?? 0.0;

      final expenses = await _dbHelper.getExpenses(adminId: adminId);
      double expensesSum = 0;
      for (var exp in expenses) {
        expensesSum += (exp['amount'] as num?)?.toDouble() ?? 0.0;
      }
      totalExpenses.value = expensesSum;
      netProfit.value = totalSales.value - totalExpenses.value;

      // Fetch charts data
      salesByCategory.value = await _dbHelper.getSalesByCategory(adminId: adminId);
      topProducts.value = await _dbHelper.getTopSellingProducts(adminId: adminId);
      
      // Monthly stats for chart
      final stats = await _dbHelper.getMonthlyStats(adminId: adminId);
      monthlyStats.value = stats.reversed.toList(); // Chronological order
      
    } catch (e) {
      print('Error fetching analytics data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
