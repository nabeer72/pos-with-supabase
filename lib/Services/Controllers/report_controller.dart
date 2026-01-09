import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';

class ReportController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  var selectedPeriod = 'Daily'.obs;
  var isLoading = true.obs;
  var salesData = <Map<String, dynamic>>[].obs;
  var summary = {'totalAmount': 0.0, 'totalCount': 0}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReportData();
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    isLoading.value = true;
    
    try {
      final stats = await _dbHelper.getSalesStatsForPeriod(selectedPeriod.value);
      
      // Convert to format expected by UI
      salesData.value = stats.map((s) => {
        'date': s['date'],
        'amount': s['amount'],
        'count': s['count'],
      }).toList();
      
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
