import 'package:flutter/material.dart';
import 'package:pos/Services/Controllers/add_customer_controller.dart';
import 'package:pos/Services/Controllers/new_sales_controller.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/customer_form.dart';
import 'package:pos/widgets/search_bar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  late NewSaleController _controller;
  late CustomerController _customerController;
  double _scannerHeight = 150;

  @override
  void initState() {
    super.initState();
    _controller = NewSaleController(context);
    _customerController = CustomerController();
  }

  // 🔸 Add Customer Popup
  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.only(left: 24, top: 20, right: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: AddCustomerForm(
                controller: _customerController,
                onCustomerAdded: () {
                  setState(() {});
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔸 Customer Selection Dialog
  void _showCustomerSelectionDialog(BuildContext context) {
    String? selectedCustomer;
    final List<Map<String, String>> _dummyCustomers = [
      {'name': 'John Doe'},
      {'name': 'Jane Smith'},
      {'name': 'Alex Johnson'},
      {'name': 'Emily Brown'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              content: DropdownButtonFormField<String>(
                value: selectedCustomer,
                decoration: InputDecoration(
                  labelText: 'Select Customer',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _dummyCustomers
                    .map((c) => DropdownMenuItem(value: c['name'], child: Text(c['name']!)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedCustomer = val),
              ),
              actions: [
                ElevatedButton(
                  onPressed: selectedCustomer == null
                      ? null
                      : () {
                          _controller.processCheckout(context, selectedCustomer);
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Checkout processed for $selectedCustomer')),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔸 Main Content
  Widget _buildMainContent(BuildContext context, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBarWidget(
            screenWidth: screenWidth,
            onSearchChanged: (value) {},
          ),
          const SizedBox(height: 16),

          // 🔹 QR Scanner Section
          if (_controller.isScanning)
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _scannerHeight = (_scannerHeight - details.delta.dy).clamp(100, 400);
                });
              },
              child: Container(
                height: _scannerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: _controller.qrScannerService.handleScanResult,
                      fit: BoxFit.cover,
                    ),
                    _buildScannerOverlay(),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _controller.setIsScanning(false)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildActionButton(
              label: "Open QR Scanner",
              icon: Icons.qr_code_scanner,
              onPressed: () => setState(() => _controller.setIsScanning(true)),
            ),

          const SizedBox(height: 20),

          // 🔹 Products Grid
          _buildProductGrid(context, isTablet, screenWidth),
          const SizedBox(height: 24),

          // 🔹 Cart Summary
          _buildCartSummary(context, screenWidth),
          const SizedBox(height: 20),

          // 🔹 Checkout
          _buildCheckoutButton(context, screenWidth),
        ],
      ),
    );
  }

  // 📱 QR Overlay
  Widget _buildScannerOverlay() => IgnorePointer(
        child: Container(
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // 🔹 Product Grid
  Widget _buildProductGrid(BuildContext context, bool isTablet, double screenWidth) {
    final cardSize = isTablet ? screenWidth * 0.22 : screenWidth * 0.28;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controller.products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final product = _controller.products[index];
            return QuickActionCard(
              title: product['name'],
              price: product['price'],
              icon: product['icon'],
              color: product['color'],
              cardSize: cardSize,
              onTap: () {
                setState(() => _controller.addToCart(product));
              },
            );
          },
        ),
      ],
    );
  }

  // 🛒 Cart Summary
  Widget _buildCartSummary(BuildContext context, double screenWidth) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cart Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          _controller.cartItems.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : Column(
                  children: _controller.cartItems.map((item) {
                    final index = _controller.cartItems.indexOf(item);
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text('\$${item['price'].toStringAsFixed(2)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () => setState(() => _controller.updateQuantity(index, -1)),
                        ),
                        Text('${item['quantity']}'),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => setState(() => _controller.updateQuantity(index, 1)),
                        ),
                      ]),
                    );
                  }).toList(),
                ),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('\$${_controller.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }

  // ✅ Checkout Button
  Widget _buildCheckoutButton(BuildContext context, double screenWidth) {
    return _buildActionButton(
      label: "Proceed to Checkout",
      icon: Icons.payment,
      onPressed:
          _controller.cartItems.isEmpty ? null : () => _showCustomerSelectionDialog(context),
    );
  }

  // 🔸 Reusable Button
  Widget _buildActionButton(
      {required String label, required IconData icon, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return _buildMainContent(context, constraints);
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
