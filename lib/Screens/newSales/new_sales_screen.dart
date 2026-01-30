import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/currency_text.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/Services/Controllers/add_customer_controller.dart';
import 'package:pos/Services/Controllers/new_sales_controller.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/customer_form.dart';
import 'package:pos/Services/printing_service.dart';
import 'package:pos/Services/models/sale_model.dart';
import 'package:pos/Services/loyalty_service.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  late final NewSaleController _controller;
  late final CustomerController _customerController;
  final TextEditingController _barcodeSearchController = TextEditingController();

  double _scannerHeight = 180;

  static const _appGradient = LinearGradient(
    colors: [
      Color.fromRGBO(30, 58, 138, 1),
      Color.fromRGBO(59, 130, 246, 1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _controller = Get.put(NewSaleController());
    _customerController = Get.put(CustomerController());
    _customerController.loadCustomers();
  }

  // ... (Add Customer & Select Customer Dialogs remain same, but update _controller calls)

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final width = MediaQuery.of(context).size.width;
        final dialogWidth = width > 600 ? 420.0 : width * 0.92;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: _dialogHeader('Add Customer', dialogContext),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: AddCustomerForm(
                controller: _customerController,
                onCustomerAdded: () {
                  Navigator.pop(dialogContext);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomerSelectionDialog() {
    String? selectedCustomer;
    final customers = _customerController.customers.map((c) => c.name).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: _dialogHeader('Select Customer', dialogContext),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: selectedCustomer,
                      decoration: _inputDecoration('Select Customer'),
                      items: _customerController.customers.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name, style: const TextStyle(color: Colors.black)))).toList(),
                      onChanged: (val) async {
                        setState(() => selectedCustomer = val);
                        setDialogState(() => selectedCustomer = val);
                        await _controller.onCustomerSelected(val);
                        final acc = _controller.loyaltyAccount.value;
                        if (acc != null && acc.totalPoints >= 50) {
                          _showLoyaltyAlert(context, acc.totalPoints);
                        }
                        setDialogState(() {}); // Refresh with loyalty account info
                      },
                    )),
                    const SizedBox(height: 16),
                    // Loyalty Account Card
                    Obx(() {
                      final acc = _controller.loyaltyAccount.value;
                      if (acc == null) return const SizedBox();
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(child: Text('Total Spend: \$${acc.lifetimeSpend.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Points', style: TextStyle(fontSize: 10)),
                                    Text('${acc.totalPoints.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Cashback', style: TextStyle(fontSize: 10)),
                                    Text('\$${acc.cashbackBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Redemption Details
                    Obx(() {
                      final acc = _controller.loyaltyAccount.value;
                      if (acc == null) return const SizedBox();
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Redeem Points', suffixText: 'pts'),
                                  onChanged: (v) {
                                    double val = double.tryParse(v) ?? 0.0;
                                    if (val > acc.totalPoints) val = acc.totalPoints;
                                    _controller.pointsToRedeem.value = val;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  enabled: acc.totalPoints >= 50,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Use Cashback', 
                                    prefixText: '\$', 
                                    helperText: acc.totalPoints < 50 ? 'Min 50 pts to redeem' : null,
                                    helperStyle: const TextStyle(color: Colors.red, fontSize: 10),
                                  ),
                                  onChanged: (v) {
                                    double val = double.tryParse(v) ?? 0.0;
                                    if (val > acc.cashbackBalance) val = acc.cashbackBalance;
                                    _controller.cashbackToUse.value = val;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Savings:', style: TextStyle(fontSize: 12)),
                                Obx(() {
                                  final rules = LoyaltyService.to.currentRules;
                                  double ptsVal = rules != null ? rules.redemptionValuePerPoint : 0.5;
                                  double savings = (_controller.pointsToRedeem.value * ptsVal) + _controller.cashbackToUse.value;
                                  return Text('-\$${savings.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green));
                                }),
                              ],
                            ),
                          ),
                          if (acc.totalPoints < 50)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '* You need at least 50 points to start redeeming.',
                                style: TextStyle(color: Colors.red, fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                _gradientButton(
                  label: 'Proceed',
                  enabled: true,
                  onTap: () async {
                    final result = await _controller.processCheckout(context, selectedCustomer);
                    Navigator.pop(dialogContext);
                    
                    if (result != null && result is Map) {
                      final sale = result['sale'] as Sale;
                      final items = result['items'] as List<Map<String, dynamic>>;
                      
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Print Receipt'),
                          content: const Text('Would you like to print the receipt for this sale?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await PrintingService().printReceipt(
                                  sale: sale, 
                                  items: items, 
                                  customerName: selectedCustomer,
                                  subtotal: result['subtotal'],
                                  discountAmount: result['discountAmount'],
                                  discountPercent: result['discountPercent'],
                                );
                              },
                              child: const Text('Print'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('New Sale', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _appGradient)),
      ),
      floatingActionButton: _fab(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Barcode Search'),
            _barcodeSearchField(),
            const SizedBox(height: 24),

            _sectionTitle('QR Scanner'),
            Obx(() => _controller.isScanning.value ? _qrScanner() : _openScannerButton()),
            const SizedBox(height: 24),

            _sectionTitle('Products'),
            _productsGrid(),
            const SizedBox(height: 24),

            _sectionTitle('Cart Summary'),
            _cartSummary(),
            const SizedBox(height: 20),

            Obx(() => _gradientButton(
              label: 'Proceed to Checkout',
              enabled: _controller.cartItems.isNotEmpty,
              onTap: _showCustomerSelectionDialog,
            )),
          ],
        ),
      ),
    );
  }

  Widget _barcodeSearchField() {
    return TextField(
      controller: _barcodeSearchController,
      decoration: InputDecoration(
        hintText: 'Enter Product Name or Code',
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (_barcodeSearchController.text.isNotEmpty) {
              _controller.searchByBarcode(_barcodeSearchController.text);
              _barcodeSearchController.clear();
              FocusScope.of(context).unfocus();
            }
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onSubmitted: (val) {
        if (val.isNotEmpty) {
          _controller.searchByBarcode(val);
          _barcodeSearchController.clear();
        }
      },
    );
  }

  Widget _qrScanner() {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        setState(() {
          _scannerHeight = (_scannerHeight - d.delta.dy).clamp(120, 400);
        });
      },
      child: Container(
        height: _scannerHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            MobileScanner(onDetect: _controller.qrScannerService.handleScanResult),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _controller.setIsScanning(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _openScannerButton() {
    return _gradientButton(
      label: 'Open QR Scanner',
      enabled: true,
      icon: Icons.qr_code_scanner,
      onTap: () => _controller.setIsScanning(true),
    );
  }

  Widget _productsGrid() {
    return Obx(() => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _controller.products.length,
      itemBuilder: (_, i) {
        final p = _controller.products[i];
        return QuickActionCard(
          title: p.name,
          price: p.price,
          icon: p.icon,
          color: const Color(0xFF253746),
          onTap: () => _controller.addToCart(p),
          cardSize: 90,
        );
      },
    ));
  }

  Widget _cartSummary() {
    return Obx(() {
      if (_controller.cartItems.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Cart is empty', style: TextStyle(color: Colors.grey)),
        ));
      }

      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            ..._controller.cartItems.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return ListTile(
                title: Text(item['name']),
                subtitle: Row(
                  children: [
                    CurrencyText(price: item['price'].toDouble()),
                    Text(' x ${item['quantity']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.orange),
                      onPressed: () => _controller.updateQuantity(i, -1),
                    ),
                    Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.blueAccent),
                      onPressed: () => _controller.updateQuantity(i, 1),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  CurrencyText(
                    price: _controller.totalAmount.value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _fab() {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _appGradient),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _showAddCustomerDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool enabled,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: enabled ? _appGradient : null,
        color: enabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: icon != null ? Icon(icon, color: Colors.white) : const SizedBox(),
        label: Text(label, style: TextStyle(color: enabled ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _dialogHeader(String title, BuildContext ctx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showLoyaltyAlert(BuildContext context, double points) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.stars, color: Colors.orange),
            SizedBox(width: 8),
            Text('Loyalty Reward!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This customer has reached ${points.toStringAsFixed(0)} points!'),
            const SizedBox(height: 12),
            const Text('They are eligible for:'),
            _bulletPoint('Discount on current purchase'),
            _bulletPoint('Free items in exchange for points'),
            _bulletPoint('Cash rewards / account credit'),
            const SizedBox(height: 12),
            const Text('You can redeem their points in the checkout section below.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
