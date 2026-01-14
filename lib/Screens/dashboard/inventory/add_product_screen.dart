import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/Services/Controllers/inventory_controller.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/widgets/custom_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final InventoryController controller = Get.find<InventoryController>();
  
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  
  String? selectedCategory;
  IconData selectedIcon = Icons.devices;
  Color selectedColor = Colors.indigo[600]!;
  
  final RxBool isScanning = false.obs;
  final RxDouble scannerHeight = 300.0.obs;

  final Map<String, IconData> icons = {
      'Electronics': Icons.devices,
      'Clothing': Icons.checkroom,
      'Accessories': Icons.watch,
      'Groceries': Icons.shopping_basket,
      'Home & Kitchen': Icons.kitchen,
      'Food & Drinks': Icons.fastfood,
      'Beauty & Care': Icons.face,
      'Automotive': Icons.directions_car,
      'Books & Stationery': Icons.menu_book,
      'Toys & Games': Icons.toys,
      'Furniture': Icons.chair,
      'Sports & Fitness': Icons.fitness_center,
      'Hardware': Icons.handyman,
      'Others': Icons.category,
  };
  
  final Map<String, Color> colors = {
      'Electronics': Colors.indigo[600]!,
      'Clothing': Colors.teal[400]!,
      'Accessories': Colors.deepOrange[400]!,
      'Groceries': Colors.green[600]!,
      'Home & Kitchen': Colors.brown[400]!,
      'Food & Drinks': Colors.red[400]!,
      'Beauty & Care': Colors.pink[300]!,
      'Automotive': Colors.blueGrey[600]!,
      'Books & Stationery': Colors.indigo[300]!,
      'Toys & Games': Colors.amber[600]!,
      'Furniture': Colors.brown[300]!,
      'Sports & Fitness': Colors.blue[600]!,
      'Hardware': Colors.orange[700]!,
      'Others': Colors.grey[600]!,
  };

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Add New Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Item Name', Icons.inventory),
              const SizedBox(height: 15),
              _buildTextField(_barcodeController, 'QR/Barcode', Icons.qr_code, suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => isScanning.value = !isScanning.value,
              )),
              
              // Scanner Section
              Obx(() => isScanning.value ? _buildScanner() : const SizedBox.shrink()),
              
              const SizedBox(height: 15),
              _buildPriceField(
                controller: _priceController,
                label: 'Sell Price',
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 16),
              _buildPriceField(
                controller: _purchasePriceController,
                label: 'Purchase Price',
                icon: Icons.money_off,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _quantityController,
                'Quantity',
                Icons.inventory_2,
                isNumber: true,
              ),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildColorSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final product = Product(
                        name: _nameController.text,
                        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
                        price: double.tryParse(_priceController.text) ?? 0.0,
                        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
                        quantity: int.tryParse(_quantityController.text) ?? 0,
                        category: selectedCategory!,
                        icon: selectedIcon,
                        color: selectedColor.value,
                      );
                      controller.addProduct(product);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Save Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Obx(() => Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400)
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Row(children: [Icon(Icons.category, color: Colors.grey), SizedBox(width: 10), Text('Select Category')]),
                value: controller.categories.contains(selectedCategory) ? selectedCategory : null,
                items: controller.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(icons[category] ?? Icons.category, color: colors[category] ?? Colors.grey),
                        const SizedBox(width: 10),
                        Text(category)
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                    selectedIcon = icons[value!] ?? Icons.category;
                    selectedColor = colors[value] ?? Colors.grey[600]!;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ),
      ],
    ));
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
            ),
            const SizedBox(width: 15),
            const Text('Selected Color'),
          ],
        )
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, String? prefixText, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a price';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            scannerHeight.value = (scannerHeight.value - details.delta.dy).clamp(150, 400);
          },
          child: Container(
            height: scannerHeight.value,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        _barcodeController.text = barcodes.first.rawValue ?? '';
                        isScanning.value = false;
                      }
                    },
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                      onPressed: () => isScanning.value = false,
                    ),
                  ),
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black54,
                      child: const Text('Scan QR/Barcode', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: catController, decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (catController.text.isNotEmpty) {
                await controller.addCategory(catController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final barcodeValue = _barcodeController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter product name', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    if (selectedCategory == null) {
      Get.snackbar('Error', 'Please select a category', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    String finalBarcode = barcodeValue.isEmpty 
       ? 'QR-${DateTime.now().millisecondsSinceEpoch}' 
       : barcodeValue;

    final newProduct = Product(
      name: name,
      barcode: finalBarcode,
      price: price,
      purchasePrice: purchasePrice, // Added purchasePrice
      category: selectedCategory!,
      icon: selectedIcon,
      quantity: quantity,
      color: selectedColor.value,
    );

    await controller.addProduct(newProduct);
    Get.back();
    Get.snackbar('Success', 'Product added successfully', backgroundColor: Colors.green, colorText: Colors.white);
  }
}
