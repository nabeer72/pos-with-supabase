import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/Services/Controllers/add_customer_controller.dart';
import 'package:pos/Services/Controllers/new_sales_controller.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/customer_form.dart';
import 'package:pos/Services/printing_service.dart';
import 'package:pos/Services/models/sale_model.dart';

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
    _customerController = CustomerController();
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
    final customers = ['John Doe', 'Jane Smith', 'Alex Johnson', 'Emily Brown'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: _dialogHeader('Select Customer', dialogContext),
              content: DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: selectedCustomer,
                decoration: _inputDecoration('Select Customer'),
                items: customers.map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(color: Colors.black)))).toList(),
                onChanged: (val) => setDialogState(() => selectedCustomer = val),
              ),
              actions: [
                _gradientButton(
                  label: 'Proceed',
                  enabled: selectedCustomer != null,
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
                                await PrintingService().printReceipt(sale: sale, items: items, customerName: selectedCustomer);
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
                subtitle: Text('Rs. ${item['price']} x ${item['quantity']}'),
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
                  Text('Rs. ${_controller.totalAmount.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
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
}
