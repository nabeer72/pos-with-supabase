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
  double _scannerHeight = 150.0; // Default value

  @override
  void initState() {
    super.initState();
    _controller = NewSaleController(context);
    _customerController = CustomerController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scannerHeight = MediaQuery.of(context).size.height * 0.25;
  }

  // 🔸 Add Customer Popup
  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Customer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: (screenWidth * 0.85).clamp(300.0, 400.0),
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
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Customer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: (screenWidth * 0.85).clamp(300.0, 400.0),
                child: DropdownButtonFormField<String>(
                  value: selectedCustomer,
                  decoration: InputDecoration(
                    labelText: 'Select Customer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _dummyCustomers
                      .map((c) => DropdownMenuItem(
                            value: c['name'],
                            child: Text(c['name']!, style: Theme.of(context).textTheme.bodySmall),
                          ))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedCustomer = val),
                ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  child: Text(
                    'Proceed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 Search Bar
          SearchBarWidget(onSearchChanged: (value) {}),
          const SizedBox(height: 20),
          // 🔹 QR Scanner Section
          Text(
            'QR Scanner',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          if (_controller.isScanning)
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _scannerHeight = (_scannerHeight - details.delta.dy)
                      .clamp(isLandscape ? screenHeight * 0.3 : 100.0, isLandscape ? screenHeight * 0.6 : 400.0);
                });
              },
              child: Container(
                height: _scannerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: _controller.qrScannerService.handleScanResult,
                      fit: BoxFit.cover,
                    ),
                    _buildScannerOverlay(screenWidth),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => setState(() => _controller.setIsScanning(false)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildActionButton(
              label: 'Open QR Scanner',
              icon: Icons.qr_code_scanner,
              onPressed: () => setState(() => _controller.setIsScanning(true)),
            ),
          const SizedBox(height: 24),
          // 🔹 Products Grid
          Text(
            'Products',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          _buildProductGrid(context, isTablet, isLandscape, screenWidth),
          const SizedBox(height: 24),
          // 🔹 Cart Summary
          Text(
            'Cart Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          _buildCartSummary(context, screenWidth, screenHeight),
          const SizedBox(height: 20),
          // 🔹 Checkout
          _buildCheckoutButton(context),
        ],
      ),
    );
  }

  // 📱 QR Overlay
  Widget _buildScannerOverlay(double screenWidth) => IgnorePointer(
        child: Container(
          margin: EdgeInsets.all(screenWidth * 0.1),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // 🔹 Product Grid
  Widget _buildProductGrid(
      BuildContext context, bool isTablet, bool isLandscape, double screenWidth) {
    final crossAxisCount = isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3);
    final cardSize = isTablet
        ? (isLandscape ? screenWidth / 6 : screenWidth / 4)
        : (isLandscape ? screenWidth / 5 : screenWidth / 3.5);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _controller.products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
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
    );
  }

  // 🛒 Cart Summary
  Widget _buildCartSummary(BuildContext context, double screenWidth, double screenHeight) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _controller.cartItems.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._controller.cartItems.map((item) {
                    final index = _controller.cartItems.indexOf(item);
                    return ListTile(
                      title: Text(
                        item['name'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      subtitle: Text(
                        '\$${item['price'].toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () => setState(() => _controller.updateQuantity(index, -1)),
                          ),
                          Text('${item['quantity']}', style: Theme.of(context).textTheme.bodySmall),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => setState(() => _controller.updateQuantity(index, 1)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      Text(
                        '\$${_controller.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // ✅ Checkout Button
  Widget _buildCheckoutButton(BuildContext context) {
    return _buildActionButton(
      label: 'Proceed to Checkout',
      icon: Icons.payment,
      onPressed: _controller.cartItems.isEmpty ? null : () => _showCustomerSelectionDialog(context),
    );
  }

  // 🔸 Reusable Button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
        title: const Text(
          'New Sale',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(Icons.person, color: Colors.deepOrangeAccent, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return _buildMainContent(context, constraints);
        }),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.person_add, color: Colors.white, size: 20),
      ),
    );
  }
}