import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Get.snackbar('Success', 'Loyalty rules updated', 
        snackPosition: SnackPosition.TOP, 
        backgroundColor: Colors.green, 
        colorText: Colors.white);
  }
}

class LoyaltyConfigScreen extends StatelessWidget {
  const LoyaltyConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoyaltyConfigController());
    const primaryBlue = Color.fromRGBO(59, 130, 246, 1);
    const darkThemeBlue = Color(0xFF253746);
    const backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(30, 58, 138, 1),
                  Color.fromRGBO(59, 130, 246, 1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'Loyalty Configuration',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Obx(() => controller.isLoading.value 
        ? const Center(child: LoadingWidget())
        : _buildRulesTab(controller, primaryBlue, darkThemeBlue)),
    );
  }

  Widget _buildRulesTab(LoyaltyConfigController controller, Color primaryBlue, Color darkThemeBlue) {
    final currencySymbol = CurrencyService().getCurrencySymbolSync();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Loyalty Program Rules', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          _buildFieldCard('Earnings Configuration', [
            _buildInput('Points per $currencySymbol 1.00 spent', controller.pointsPerUnit, Icons.stars, darkThemeBlue),
            _buildInput('Point Value (Redemption)', controller.pointValue, Icons.attach_money, darkThemeBlue),
            Row(
              children: [
                Expanded(child: _buildInput('Cashback Percentage (%)', controller.cashbackPercent, Icons.monetization_on, darkThemeBlue)),
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8),
                  child: IconButton(
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
                ),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _buildFieldCard('Expiry Configuration', [
            _buildInput('Points Expiry (Months)', controller.expiryMonths, Icons.timer, darkThemeBlue),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: controller.saveRules,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Loyalty Rules', 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          // Info Card
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: primaryBlue.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These rules define how customers earn and redeem points in your store.',
                      style: TextStyle(
                         color: primaryBlue.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: iconColor, size: 22),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color.fromRGBO(59, 130, 246, 1), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
