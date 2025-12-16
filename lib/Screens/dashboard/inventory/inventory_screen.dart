import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/custom_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Map<String, dynamic>> _inventoryItems = [
    {
      'name': 'Product A',
      'price': 29.99,
      'quantity': 50,
      'category': 'Electronics',
      'icon': Icons.devices,
      'color': const Color(0xFF253746),
    },
    {
      'name': 'Product B',
      'price': 19.99,
      'quantity': 30,
      'category': 'Clothing',
      'icon': Icons.checkroom,
      'color': const Color(0xFF253746),
    },
    {
      'name': 'Product C',
      'price': 49.99,
      'quantity': 20,
      'category': 'Electronics',
      'icon': Icons.devices,
      'color': const Color(0xFF253746),
    },
    {
      'name': 'Product D',
      'price': 9.99,
      'quantity': 100,
      'category': 'Accessories',
      'icon': Icons.watch,
      'color': const Color(0xFF253746),
    },
    {
      'name': 'Product E',
      'price': 39.99,
      'quantity': 15,
      'category': 'Clothing',
      'icon': Icons.checkroom,
      'color': const Color(0xFF253746),
    },
    {
      'name': 'Product F',
      'price': 24.99,
      'quantity': 40,
      'category': 'Accessories',
      'icon': Icons.watch,
      'color': const Color(0xFF253746),
    },
  ];

  void _showAddItemDialog(BuildContext context) {
    // ... (your existing _showAddItemDialog code remains unchanged)
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    String? selectedCategory;
    IconData selectedIcon = Icons.devices;
    Color selectedColor = Colors.indigo[600]!;
    bool isScanningInDialog = false;
    double scannerHeightInDialog = 150;

    final categories = _inventoryItems
        .where((item) => item['category'] != null)
        .map((item) => item['category'] as String)
        .toSet()
        .toList();
    
    final icons = {
      'Electronics': Icons.devices,
      'Clothing': Icons.checkroom,
      'Accessories': Icons.watch,
    };
    final colors = {
      'Electronics': Colors.indigo[600]!,
      'Clothing': Colors.teal[400]!,
      'Accessories': Colors.deepOrange[400]!,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Item'),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value;
                          selectedIcon = icons[value] ?? Icons.devices;
                          selectedColor = colors[value] ?? Colors.indigo[600]!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isScanningInDialog)
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          setDialogState(() {
                            scannerHeightInDialog = (scannerHeightInDialog - details.delta.dy).clamp(100, 400);
                          });
                        },
                        child: SizedBox(
                          width: 280,
                          height: scannerHeightInDialog,
                          child: ColoredBox(
                            color: Colors.black,
                            child: Stack(
                              children: [
                                MobileScanner(
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    for (final barcode in barcodes) {
                                      final scannedValue = barcode.rawValue ?? 'Unknown';
                                      setDialogState(() {
                                        nameController.text = scannedValue;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Scanned: $scannedValue')),
                                      );
                                    }
                                    setDialogState(() {
                                      isScanningInDialog = false;
                                    });
                                  },
                                  fit: BoxFit.cover,
                                ),
                                _customScannerOverlay(),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                    onPressed: () => setDialogState(() => isScanningInDialog = false),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.white.withOpacity(0.3),
                                    height: 20,
                                    child: const Center(
                                      child: Icon(Icons.drag_handle, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                CustomButton(
                  text: 'Scan QR Code',
                  onPressed: () {
                    setDialogState(() {
                      isScanningInDialog = !isScanningInDialog;
                    });
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Add Item',
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim());
                    final quantity = int.tryParse(quantityController.text.trim());

                    if (name.isEmpty || price == null || quantity == null || selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields correctly')),
                      );
                      return;
                    }

                    setState(() {
                      _inventoryItems.add({
                        'name': name,
                        'price': price,
                        'quantity': quantity,
                        'category': selectedCategory,
                        'icon': selectedIcon,
                        'color': selectedColor,
                      });
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name added to inventory')),
                    );
                    Get.back();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final newQuantity = (_inventoryItems[index]['quantity'] as int) + change;
      if (newQuantity >= 0) {
        _inventoryItems[index]['quantity'] = newQuantity;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot reduce quantity below 0 for ${_inventoryItems[index]['name']}')),
        );
      }
    });
  }

  Widget _customScannerOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(50),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100], // ← Set background on Scaffold
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.05,
              vertical: constraints.maxHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildInventoryGrid(context, constraints.maxWidth),
                SizedBox(height: constraints.maxHeight * 0.03),
                _buildAddInventoryButton(context, constraints.maxWidth),
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildInventorySummary(context, constraints.maxWidth, constraints.maxHeight),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryGrid(BuildContext context, double screenWidth) {
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3);
    final cardSize = screenWidth / crossAxisCount - 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Items',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: _inventoryItems.length,
          itemBuilder: (context, index) {
            final item = _inventoryItems[index];
            return QuickActionCard(
              title: item['name'],
              price: item['price'],
              icon: item['icon'],
              color: item['color'],
              cardSize: cardSize,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected ${item['name']}')),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddInventoryButton(BuildContext context, double screenWidth) {
    return CustomButton(
      text: 'Add to Inventory',
      onPressed: () => _showAddItemDialog(context),
    );
  }

  Widget _buildInventorySummary(
      BuildContext context, double screenWidth, double screenHeight) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Summary',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: screenHeight * 0.2,
              child: ListView.builder(
                itemCount: _inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = _inventoryItems[index];
                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text('Price: \$${item['price'].toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _updateQuantity(index, -1),
                        ),
                        Text('${item['quantity']}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _updateQuantity(index, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}