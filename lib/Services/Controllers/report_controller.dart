import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/receipt_service.dart';

class ReportController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReceiptService _receiptService = ReceiptService();
  
  var selectedPeriod = 'Daily'.obs;
  var isLoading = true.obs;
  var salesData = <Map<String, dynamic>>[].obs;
  var detailedSales = <Map<String, dynamic>>[].obs;
  var summary = {'totalAmount': 0.0, 'totalCount': 0}.obs;
  var storeName = 'My Store'.obs;

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

      // Fetch store name from receipt settings
      final receiptSettings = await _receiptService.getReceiptSettings();
      storeName.value = receiptSettings['store_name'] ?? 'My Store';

      List<Map<String, dynamic>> stats;
      List<Map<String, dynamic>> detailed;

      if (selectedPeriod.value == 'Custom' && customStartDate.value != null && customEndDate.value != null) {
        String startStr = customStartDate.value!.toString().split(' ')[0];
        String endStr = customEndDate.value!.toString().split(' ')[0];
        stats = await _dbHelper.getSalesStatsForCustomPeriod(startStr, endStr, adminId: adminId);
        detailed = await _dbHelper.getDetailedSales(adminId: adminId, startDate: startStr, endDate: endStr);
      } else {
        stats = await _dbHelper.getSalesStatsForPeriod(selectedPeriod.value, adminId: adminId);
        detailed = await _dbHelper.getDetailedSales(adminId: adminId, period: selectedPeriod.value);
      }
      
      // Convert stats to format expected by UI chart
      salesData.value = _zeroFillStats(stats, selectedPeriod.value);

      detailedSales.value = detailed;
      
      // Calculate total summary specifically for the selected period from the detailed list
      double totalAmount = 0;
      int totalCount = detailed.length;
      for (var s in detailed) {
        totalAmount += (s['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }
      
      summary.value = {'totalAmount': totalAmount, 'totalCount': totalCount};
    } catch (e) {
      print('Error fetching report data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _zeroFillStats(List<Map<String, dynamic>> stats, String period) {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> filled = [];
    
    // Convert current labels to map for easy lookup
    Map<String, Map<String, dynamic>> statsMap = {
      for (var s in stats) s['date'].toString(): s
    };

    if (period == 'Daily') {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        filled.add(statsMap[key] ?? {'date': key, 'amount': 0.0, 'count': 0});
      }
    } else if (period == 'Weekly') {
       // Last 4 weeks (Simplified)
       // The DB returns YYYY-WW. 
       for (int i = 3; i >= 0; i--) {
         DateTime date = now.subtract(Duration(days: i * 7));
         // Need to match SQLite strftime('%Y-%W', ...) behavior
         // We'll just use the stats provided or generate a key if we expect a full range
         // For now, let's keep stats as is or just return stats if we don't have a reliable WW generator
         return stats.reversed.toList(); // Return reversed for ASC order in chart
       }
    } else if (period == 'Monthly') {
      // Last 6 months
      for (int i = 5; i >= 0; i--) {
        DateTime date = DateTime(now.year, now.month - i, 1);
        String key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        filled.add(statsMap[key] ?? {'date': key, 'amount': 0.0, 'count': 0});
      }
    } else if (period == 'Yearly') {
       // Just show what we have, usually not many years
       return stats.reversed.toList();
    } else {
       return stats.reversed.toList();
    }

    return filled;
  }
}
