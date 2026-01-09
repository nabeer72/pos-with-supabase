import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';

class DashboardController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  var salesSummary = {'totalAmount': 0.0, 'totalCount': 0}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final summary = await _dbHelper.getSalesSummary();
      salesSummary.value = {
        'totalAmount': (summary['totalAmount'] as num?)?.toDouble() ?? 0.0,
        'totalCount': (summary['totalCount'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
