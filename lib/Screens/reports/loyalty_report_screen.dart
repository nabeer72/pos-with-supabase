import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/widgets/currency_text.dart';
import 'package:pos/widgets/custom_loader.dart';

class LoyaltyReportController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  final totalPointsEarned = 0.0.obs;
  final totalPointsRedeemed = 0.0.obs;
  final totalCashbackEarned = 0.0.obs;
  final totalCashbackUsed = 0.0.obs;
  
  final topCustomers = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final adminId = Get.find<AuthController>().adminId;
    if (adminId == null) return;

    final db = await _dbHelper.database;
    
    // Aggregate data
    final stats = await db.rawQuery('''
      SELECT 
        SUM(points_earned) as earned, 
        SUM(points_redeemed) as redeemed,
        SUM(cashback_earned) as cb_earned,
        SUM(cashback_used) as cb_used
      FROM loyalty_transactions
      WHERE admin_id = ?
    ''', [adminId]);

    if (stats.isNotEmpty) {
      totalPointsEarned.value = (stats.first['earned'] as num?)?.toDouble() ?? 0.0;
      totalPointsRedeemed.value = (stats.first['redeemed'] as num?)?.toDouble() ?? 0.0;
      totalCashbackEarned.value = (stats.first['cb_earned'] as num?)?.toDouble() ?? 0.0;
      totalCashbackUsed.value = (stats.first['cb_used'] as num?)?.toDouble() ?? 0.0;
    }

    // Top Customers by lifetime spend
    final customers = await db.rawQuery('''
      SELECT c.name, la.current_tier, la.lifetime_spend
      FROM loyalty_accounts la
      JOIN customers c ON la.customer_id = c.id
      WHERE la.admin_id = ?
      ORDER BY la.lifetime_spend DESC
      LIMIT 10
    ''', [adminId]);
    
    topCustomers.assignAll(customers);
    isLoading.value = false;
  }
}

class LoyaltyReportScreen extends StatelessWidget {
  const LoyaltyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoyaltyReportController());
    const primaryBlue = Color.fromRGBO(59, 130, 246, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Insights', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
            ),
          ),
        ),
      ),
      body: Obx(() => controller.isLoading.value 
        ? const Center(child: LoadingWidget())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsRow(controller),
              const SizedBox(height: 24),
              _buildSectionTitle('Top 10 Loyal Customers'),
              _buildCustomersList(controller, primaryBlue),
            ],
          )),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatsRow(LoyaltyReportController controller) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Points Earned', '${controller.totalPointsEarned.value.toStringAsFixed(0)}', Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard('Points Redeemed', '${controller.totalPointsRedeemed.value.toStringAsFixed(0)}', Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Cashback Issued', '\$${controller.totalCashbackEarned.value.toStringAsFixed(2)}', Colors.green),
            const SizedBox(width: 12),
            _buildStatCard('Cashback Used', '\$${controller.totalCashbackUsed.value.toStringAsFixed(2)}', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList(LoyaltyReportController controller, Color primaryBlue) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Column(
        children: controller.topCustomers.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: i < 3 ? Colors.orange[400] : Colors.grey[300],
              child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Tier: ${c['current_tier']}'),
            trailing: CurrencyText(
              price: (c['lifetime_spend'] as num).toDouble(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          );
        }).toList(),
      ),
    );
  }
}
