import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class ReportController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  var selectedPeriod = 'Daily'.obs;
  var isLoading = true.obs;
  var salesData = <Map<String, dynamic>>[].obs;
  var detailedSales = <Map<String, dynamic>>[].obs;
  var summary = {'totalAmount': 0.0, 'totalCount': 0}.obs;

  var customStartDate = Rxn<DateTime>();
  var customEndDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchReportData();
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    customStartDate.value = null;
    customEndDate.value = null;
    fetchReportData();
  }

  void setCustomRange(DateTime start, DateTime end) {
    selectedPeriod.value = 'Custom';
    customStartDate.value = start;
    customEndDate.value = end;
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    isLoading.value = true;
    
    try {
      final authController = Get.find<AuthController>();
      final adminId = authController.adminId;

      List<Map<String, dynamic>> stats;
      List<Map<String, dynamic>> detailed;

      if (selectedPeriod.value == 'Custom' && customStartDate.value != null && customEndDate.value != null) {
        String startStr = customStartDate.value!.toString().split(' ')[0];
        String endStr = customEndDate.value!.toString().split(' ')[0];
        stats = await _dbHelper.getSalesStatsForCustomPeriod(startStr, endStr, adminId: adminId);
        detailed = await _dbHelper.getDetailedSales(adminId: adminId, startDate: startStr, endDate: endStr);
      } else {
        stats = await _dbHelper.getSalesStatsForPeriod(selectedPeriod.value, adminId: adminId);
        
        // For standard periods, we can approximate the range for detailed list
        // Simple approach: if Daily, fetch for today. If Weekly, fetch last 7 days.
        DateTime now = DateTime.now();
        String todayStr = now.toString().split(' ')[0];
        
        if (selectedPeriod.value == 'Daily') {
          detailed = await _dbHelper.getDetailedSales(adminId: adminId, startDate: todayStr, endDate: todayStr);
        } else {
          // For Weekly/Monthly/Yearly, let's just show recent ones if we don't calculate the exact window
          // Better: Use a larger window or just fetch all for now and filter (but it's better to calculate)
          detailed = await _dbHelper.getDetailedSales(adminId: adminId, period: selectedPeriod.value);
        }
      }
      
      // Convert stats to format expected by UI chart
      salesData.value = stats.map((s) => {
        'date': s['date'],
        'amount': s['amount'],
        'count': s['count'],
      }).toList();

      detailedSales.value = detailed;
      
      // Calculate total summary for the loaded period
      double totalAmount = 0;
      int totalCount = 0;
      for (var s in stats) {
        totalAmount += (s['amount'] as num?)?.toDouble() ?? 0.0;
        totalCount += (s['count'] as num?)?.toInt() ?? 0;
      }
      
      summary.value = {'totalAmount': totalAmount, 'totalCount': totalCount};
    } catch (e) {
      print('Error fetching report data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
