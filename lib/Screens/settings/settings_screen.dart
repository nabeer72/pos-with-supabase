import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:pos/Services/receipt_service.dart';
import 'package:pos/Services/backup_service.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:pos/Services/models/currency_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currencyService = CurrencyService();
  final _receiptService = ReceiptService();
  final _backupService = BackupService();
  
  Currency? _selectedCurrency;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Backup Settings
  bool _isAutoBackupEnabled = true;
  bool _isManualBackupEnabled = true;

  // Receipt Settings
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _footerController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final adminId = Get.find<AuthController>().adminId;
      if (adminId == null) throw 'Admin ID not found';

      final currency = await _currencyService.getCurrentCurrency();
      final receiptSettings = await _receiptService.getReceiptSettings();
      final discount = await _receiptService.getDefaultDiscount();
      
      final autoBackup = await _backupService.isAutoBackupEnabled(adminId);
      final manualBackup = await _backupService.isManualBackupEnabled(adminId);

      setState(() {
        _selectedCurrency = currency;
        _isAutoBackupEnabled = autoBackup;
        _isManualBackupEnabled = manualBackup;
        _storeNameController.text = receiptSettings['store_name'] ?? '';
        _storeAddressController.text = receiptSettings['store_address'] ?? '';
        _storePhoneController.text = receiptSettings['store_phone'] ?? '';
        _footerController.text = receiptSettings['receipt_footer'] ?? '';
        _discountController.text = discount.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    final adminId = Get.find<AuthController>().adminId;
    if (adminId == null) return;
    
    setState(() => _isAutoBackupEnabled = enabled);
    await _backupService.setAutoBackupEnabled(adminId, enabled);
  }

  Future<void> _toggleManualBackup(bool enabled) async {
    final adminId = Get.find<AuthController>().adminId;
    if (adminId == null) return;

    setState(() => _isManualBackupEnabled = enabled);
    await _backupService.setManualBackupEnabled(adminId, enabled);
  }

  Future<void> _performManualBackup() async {
    setState(() => _isSaving = true);
    try {
      await _backupService.performBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual backup created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveReceiptSettings() async {
    setState(() => _isSaving = true);
    try {
      await _receiptService.updateReceiptSettings({
        'store_name': _storeNameController.text,
        'store_address': _storeAddressController.text,
        'store_phone': _storePhoneController.text,
        'receipt_footer': _footerController.text,
      });
      
      final discount = double.tryParse(_discountController.text) ?? 0.0;
      await _receiptService.setDefaultDiscount(discount);

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // DISPOSE FORM (Navigate back)
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCurrency(Currency currency) async {
    setState(() => _isSaving = true);
    try {
      await _currencyService.setCurrency(currency);
      setState(() {
        _selectedCurrency = currency;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Currency updated to ${currency.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving currency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: CurrencyList.currencies.length,
                itemBuilder: (context, index) {
                  final currency = CurrencyList.currencies[index];
                  final isSelected = _selectedCurrency?.code == currency.code;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      currency.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('${currency.code} (${currency.symbol})'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _saveCurrency(currency);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Settings',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                // Currency Settings Section
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.grey.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Currency Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryBlue,
                          child: Text(
                            _selectedCurrency?.symbol ?? '\$',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _selectedCurrency != null
                              ? '${_selectedCurrency!.name} (${_selectedCurrency!.code})'
                              : 'Not set',
                        ),
                        trailing: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _isSaving ? null : _showCurrencyPicker,
                      ),
                    ],
                  ),
                ),

                // Backup Settings Section
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.grey.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backup Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBackupToggle(
                          title: 'Automatic Backup',
                          subtitle: 'Performs backup every week (7 days)',
                          icon: Icons.auto_mode,
                          isActive: _isAutoBackupEnabled,
                          onChanged: _toggleAutoBackup,
                          iconColor: darkThemeBlue,
                        ),
                        const Divider(height: 24),
                        _buildBackupToggle(
                          title: 'Manual Backup',
                          subtitle: 'Enables the ability to backup manually',
                          icon: Icons.backup,
                          isActive: _isManualBackupEnabled,
                          onChanged: _toggleManualBackup,
                          iconColor: darkThemeBlue,
                        ),
                        if (_isManualBackupEnabled) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _performManualBackup,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Perform Manual Backup Now'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: primaryBlue),
                                foregroundColor: primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                const SizedBox(height: 16),

                // Receipt Customization Section
                Card(
                  elevation: 2,
                  shadowColor: Colors.grey.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Receipt Customization',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsField('Store Name', _storeNameController, Icons.store, darkThemeBlue),
                        const SizedBox(height: 12),
                        _buildSettingsField('Store Address', _storeAddressController, Icons.location_on, darkThemeBlue),
                        const SizedBox(height: 12),
                        _buildSettingsField('Contact Number', _storePhoneController, Icons.phone, darkThemeBlue),
                        const SizedBox(height: 12),
                        _buildSettingsField('Receipt Footer', _footerController, Icons.message, darkThemeBlue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Discounts Section
                Card(
                  color : Colors.white,
                  elevation: 2,
                  shadowColor: Colors.grey.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discounts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsField(
                          'Default Discount (%)', 
                          _discountController, 
                          Icons.percent,
                          darkThemeBlue,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveReceiptSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save All Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        const Icon(Icons.info_outline, color: primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your preferences are saved per admin account and will be applied to your transactions and receipts.',
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

  Widget _buildSettingsField(String label, TextEditingController controller, IconData icon, Color iconColor, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
    );
  }

  Widget _buildBackupToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Function(bool) onChanged,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton('Active', true, isActive, () => onChanged(true)),
            const SizedBox(width: 8),
            _buildToggleButton('Deactive', false, !isActive, () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool value, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (value ? Colors.green : Colors.red) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
