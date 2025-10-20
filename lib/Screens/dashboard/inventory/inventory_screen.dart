import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/search_bar.dart'; // Import SearchBarWidget
import 'package:pos/widgets/custom_button.dart'; // Import CustomButton
import 'package:mobile_scanner/mobile_scanner.dart'; // Import MobileScanner

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Sample inventory data
  final List<Map<String, dynamic>> _inventoryItems = [
    {
      'name': 'Product A',
      'price': 29.99,
      'quantity': 50,
      'category': 'Electronics',
      'icon': Icons.devices,
      'color': Colors.indigo[600]!
    },
    {
      'name': 'Product B',
      'price': 19.99,
      'quantity': 30,
      'category': 'Clothing',
      'icon': Icons.checkroom,
      'color': Colors.teal[400]!
    },
    {
      'name': 'Product C',
      'price': 49.99,
      'quantity': 20,
      'category': 'Electronics',
      'icon': Icons.devices,
      'color': Colors.purple[400]!
    },
    {
      'name': 'Product D',
      'price': 9.99,
      'quantity': 100,
      'category': 'Accessories',
      'icon': Icons.watch,
      'color': Colors.deepOrange[400]!
    },
    {
      'name': 'Product E',
      'price': 39.99,
      'quantity': 15,
      'category': 'Clothing',
      'icon': Icons.checkroom,
      'color': Colors.blue[400]!
    },
    {
      'name': 'Product F',
      'price': 24.99,
      'quantity': 40,
      'category': 'Accessories',
      'icon': Icons.watch,
      'color': Colors.green[400]!
    },
  ];

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    String? selectedCategory;
    IconData selectedIcon = Icons.devices;
    Color selectedColor = Colors.indigo[600]!;
    bool isScanningInDialog = false; // State for QR scanner in dialog
    double scannerHeightInDialog = 150; // Default scanner height in dialog

    // Dynamically get unique non-null categories from _inventoryItems
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
                                        nameController.text = scannedValue; // Populate name field with scanned value
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Scanned: $scannedValue')),
                                      );
                                    }
                                    setDialogState(() {
                                      isScanningInDialog = false; // Close scanner after scan
                                    });
                                  },
                                  fit: BoxFit.cover,
                                ),
                                _customScannerOverlay(),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                const SizedBox(height: 12), // Spacing between buttons
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

                    Navigator.pop(context); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name added to inventory')),
                    );
                    Get.back(); // Navigate back to DashboardScreen
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

  // Custom overlay for QR scan guide
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
            color: Colors.black54, // Semi-transparent to show camera
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ignore: unused_local_variable
    final screenHeight = MediaQuery.of(context).size.height;
    // ignore: unused_local_variable
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: TextStyle(
            fontSize: isLargeScreen ? 24 : screenWidth * 0.05,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.deepOrangeAccent, // White background for the AppBar
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              // Placeholder for refreshing inventory data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inventory refreshed')),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            child: CircleAvatar(
              radius: isLargeScreen ? 20 : screenWidth * 0.04,
              backgroundColor: Colors.white,
              child: Icon(Icons.person,
                  size: isLargeScreen ? 24 : screenWidth * 0.045,
                  color: Colors.black),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100], // Set Colors.grey[100] as the background
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: constraints.maxHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar using SearchBarWidget
                  SearchBarWidget(
                   
                    onSearchChanged: (value) {
                      // Implement inventory search logic here
                    },
                  ),
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
      ),
    );
  }

  Widget _buildInventoryGrid(BuildContext context, double screenWidth) {
    final cardSize = screenWidth * 0.28; // Adjusted for 3 cards per row

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Items',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Fixed to 3 cards per row
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: _inventoryItems.length,
          itemBuilder: (context, index) {
            final item = _inventoryItems[index];
            return QuickActionCard(
              title: item['name'],
              price: item['price'], // Pass price as double
              icon: item['icon'],
              color: item['color'],
              cardSize: cardSize,
              onTap: () {
                // Placeholder for item details or edit action
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