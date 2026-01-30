import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/loyalty_service.dart';
import 'package:pos/Services/models/loyalty_config_model.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:pos/Services/currency_service.dart';

class LoyaltyConfigController extends GetxController {
  final LoyaltyService _loyaltyService = LoyaltyService.to;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final pointsPerUnit = TextEditingController();
  final cashbackPercent = TextEditingController();
  final expiryMonths = TextEditingController();
  final pointValue = TextEditingController();

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

    await _loyaltyService.loadConfig(adminId);
    
    final rules = _loyaltyService.currentRules;
    if (rules != null) {
      pointsPerUnit.text = rules.pointsPerCurrencyUnit.toString();
      cashbackPercent.text = rules.cashbackPercentage.toString();
      expiryMonths.text = rules.pointsExpiryMonths.toString();
      pointValue.text = rules.redemptionValuePerPoint.toString();
    }

    isLoading.value = false;
  }

  Future<void> saveRules() async {
    final adminId = Get.find<AuthController>().adminId;
    if (adminId == null) return;

    final rule = LoyaltyRule(
      pointsPerCurrencyUnit: double.tryParse(pointsPerUnit.text) ?? 1.0,
      cashbackPercentage: double.tryParse(cashbackPercent.text) ?? 0.0,
      pointsExpiryMonths: int.tryParse(expiryMonths.text) ?? 12,
      redemptionValuePerPoint: double.tryParse(pointValue.text) ?? 0.5,
      adminId: adminId,
    );

    await _dbHelper.updateLoyaltyRules(rule.toMap());
    await load();
    SupabaseService().syncData();
    Get.snackbar('Success', 'Loyalty rules updated', snackPosition: SnackPosition.TOP);
  }
}

class LoyaltyConfigScreen extends StatelessWidget {
  const LoyaltyConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoyaltyConfigController());
    final primaryBlue = const Color.fromRGBO(59, 130, 246, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Configuration', style: TextStyle(color: Colors.white)),
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
        : _buildRulesTab(controller, primaryBlue)),
    );
  }

  Widget _buildRulesTab(LoyaltyConfigController controller, Color primaryBlue) {
    final currencySymbol = CurrencyService().getCurrencySymbolSync();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldCard('Earnings Configuration', [
            _buildInput('Points per $currencySymbol 1.00 spent', controller.pointsPerUnit, Icons.stars),
            _buildInput('Point Value (Redemption)', controller.pointValue, Icons.attach_money),
            Row(
              children: [
                Expanded(child: _buildInput('Cashback Percentage (%)', controller.cashbackPercent, Icons.monetization_on)),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.blueGrey),
                  onPressed: () => Get.defaultDialog(
                    title: 'Cashback Explanation',
                    middleText: 'A percentage of the total purchase amount is returned to the customer as "Cashback" in their account. This balance can be used to pay for future purchases.',
                    textConfirm: 'Got it',
                    confirmTextColor: Colors.white,
                    buttonColor: primaryBlue,
                    onConfirm: () => Get.back(),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _buildFieldCard('Expiry Configuration', [
            _buildInput('Points Expiry (Months)', controller.expiryMonths, Icons.timer),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: controller.saveRules,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Rules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
