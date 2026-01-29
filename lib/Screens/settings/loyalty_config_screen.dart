import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/loyalty_service.dart';
import 'package:pos/Services/models/loyalty_config_model.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/widgets/custom_loader.dart';

class LoyaltyConfigController extends GetxController {
  final LoyaltyService _loyaltyService = LoyaltyService.to;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final pointsPerUnit = TextEditingController();
  final cashbackPercent = TextEditingController();
  final expiryMonths = TextEditingController();

  final tiers = <LoyaltyTier>[].obs;
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
    }

    tiers.assignAll(_loyaltyService.currentTiers ?? []);
    isLoading.value = false;
  }

  Future<void> saveRules() async {
    final adminId = Get.find<AuthController>().adminId;
    if (adminId == null) return;

    final rule = LoyaltyRule(
      pointsPerCurrencyUnit: double.tryParse(pointsPerUnit.text) ?? 1.0,
      cashbackPercentage: double.tryParse(cashbackPercent.text) ?? 0.0,
      pointsExpiryMonths: int.tryParse(expiryMonths.text) ?? 12,
      adminId: adminId,
    );

    await _dbHelper.updateLoyaltyRules(rule.toMap());
    await load();
    SupabaseService().syncData();
    Get.snackbar('Success', 'Loyalty rules updated', snackPosition: SnackPosition.TOP);
  }

  Future<void> updateTier(LoyaltyTier tier) async {
    await _dbHelper.updateLoyaltyTier(tier.toMap());
    await load();
    SupabaseService().syncData();
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
        bottom: const TabBar(
          tabs: [
            Tab(text: 'General Rules', icon: Icon(Icons.rule, color: Colors.white)),
            Tab(text: 'Tier Levels', icon: Icon(Icons.layers, color: Colors.white)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Obx(() => controller.isLoading.value 
          ? const Center(child: LoadingWidget())
          : TabBarView(
              children: [
                _buildRulesTab(controller, primaryBlue),
                _buildTiersTab(controller, primaryBlue),
              ],
            )),
      ),
    );
  }

  Widget _buildRulesTab(LoyaltyConfigController controller, Color primaryBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldCard('Earnings Configuration', [
            _buildInput('Points per 1.00 spent', controller.pointsPerUnit, Icons.stars),
            _buildInput('Cashback Percentage (%)', controller.cashbackPercent, Icons.monetization_on),
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

  Widget _buildTiersTab(LoyaltyConfigController controller, Color primaryBlue) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.tiers.length,
      itemBuilder: (context, index) {
        final tier = controller.tiers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryBlue,
              child: Text(tier.tierName[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(tier.tierName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Spend: \$${tier.spendRangeMin} - \$${tier.spendRangeMax}\nDiscount: ${tier.discountPercentage}%'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditTierDialog(context, controller, tier),
            ),
          ),
        );
      },
    );
  }

  void _showEditTierDialog(BuildContext context, LoyaltyConfigController controller, LoyaltyTier tier) {
    final min = TextEditingController(text: tier.spendRangeMin.toString());
    final max = TextEditingController(text: tier.spendRangeMax.toString());
    final disc = TextEditingController(text: tier.discountPercentage.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${tier.tierName} Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: min, decoration: const InputDecoration(labelText: 'Min Spend')),
            TextField(controller: max, decoration: const InputDecoration(labelText: 'Max Spend')),
            TextField(controller: disc, decoration: const InputDecoration(labelText: 'Discount (%)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateTier(LoyaltyTier(
                id: tier.id,
                tierName: tier.tierName,
                spendRangeMin: double.tryParse(min.text) ?? tier.spendRangeMin,
                spendRangeMax: double.tryParse(max.text) ?? tier.spendRangeMax,
                discountPercentage: double.tryParse(disc.text) ?? tier.discountPercentage,
                adminId: tier.adminId,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
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
