import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/Services/models/sale_model.dart';
import 'package:pos/Services/models/sale_item_model.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/receipt_service.dart';
import 'package:pos/Services/loyalty_service.dart';
import 'package:pos/Services/models/loyalty_account_model.dart';
import 'package:pos/Services/models/customer_model.dart';
import 'package:pos/Services/audio_service.dart';

// QR Scanner Service to handle QR scanning logic
class QRScannerService {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onProductFound;
  final Function(String) onError;

  QRScannerService({
    required this.products,
    required this.onProductFound,
    required this.onError,
  });

  void handleScanResult(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final scannedCode = barcode.rawValue!;
        try {
          // Match QR code to product barcode first, then name as fallback
          final product = products.firstWhere(
            (p) => p['barcode'] == scannedCode || p['name'] == scannedCode,
          );
          AudioService().playScanBeep();
          onProductFound(product);
        } catch (e) {
          onError('Product not found for code: $scannedCode');
        }
        return; // Process only the first valid barcode
      }
    }
  }
}

// Controller to handle business logic for NewSaleScreen
class NewSaleController extends GetxController {
  final cartItems = <Map<String, dynamic>>[].obs;
  final totalAmount = 0.0.obs;
  final isScanning = false.obs;
  final products = <Product>[].obs;
  
  // Loyalty Observables
  final pointsToRedeem = 0.0.obs;
  final cashbackToUse = 0.0.obs;
  final loyaltyAccount = Rxn<LoyaltyAccount>();
  final selectedCustomerModel = Rxn<CustomerModel>();

  late QRScannerService qrScannerService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    LoyaltyService.to.init(); // Ensure loyalty service is ready
  }

  Future<void> onCustomerSelected(String? customerName) async {
    pointsToRedeem.value = 0.0;
    cashbackToUse.value = 0.0;
    
    if (customerName == null) {
      loyaltyAccount.value = null;
      selectedCustomerModel.value = null;
      return;
    }

    final authController = Get.find<AuthController>();
    final customers = await _dbHelper.getCustomers(adminId: authController.adminId);
    final customer = customers.firstWhereOrNull((c) => c.name == customerName);
    
    if (customer != null && customer.id != null) {
      selectedCustomerModel.value = customer;
      loyaltyAccount.value = await LoyaltyService.to.getAccount(customer.id!);
    } else {
      loyaltyAccount.value = null;
      selectedCustomerModel.value = null;
    }
  }

  Future<void> _loadProducts() async {
    final authController = Get.find<AuthController>();
    final loadedProducts = await _dbHelper.getProducts(adminId: authController.adminId);
    products.assignAll(loadedProducts);
    
    qrScannerService = QRScannerService(
      products: products.map((p) => p.toMap()).toList(),
      onProductFound: (productMap) {
        final product = Product.fromMap(productMap);
        if (addToCart(product)) {
          setIsScanning(false);
        }
      },
      onError: (message) {
        Get.snackbar(
          'Error',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setIsScanning(false);
      },
    );
  }

  bool addToCart(Product product) {
    // Check if product is in stock
    if (product.quantity <= 0) {
      Get.snackbar(
        'Out of Stock',
        '${product.name} is currently out of stock',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Check if product already in cart
    final index = cartItems.indexWhere((item) => item['id'] == product.id);
    if (index != -1) {
      return updateQuantity(index, 1);
    } else {
      cartItems.add({...product.toMap(), 'quantity': 1});
      totalAmount.value += product.price;
      
      Get.snackbar(
        'Product Added',
        'Added ${product.name} to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    }
  }

  void searchByBarcode(String barcode) {
    try {
      final product = products.firstWhere(
        (p) => p.barcode == barcode || p.name.toLowerCase() == barcode.toLowerCase(),
      );
      addToCart(product);
    } catch (e) {
      Get.snackbar(
        'Not Found',
        'No product found with code: $barcode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  bool updateQuantity(int index, int change) {
    final item = cartItems[index];
    final int currentQtyInCart = item['quantity'] as int;
    final int newQuantity = currentQtyInCart + change;

    // Find the product in the master list to check total stock
    final product = products.firstWhereOrNull((p) => p.id == item['id']);
    
    if (change > 0 && product != null) {
      if (newQuantity > product.quantity) {
        Get.snackbar(
          'Limit Reached',
          'Only ${product.quantity} items available in stock',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    }
    
    if (newQuantity > 0) {
      totalAmount.value += change * (item['price'] as num).toDouble();
      final Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
      newItem['quantity'] = newQuantity;
      cartItems[index] = newItem;
      
      if (change > 0) {
        Get.snackbar(
          'Updated',
          'Increased ${item['name']} quantity to $newQuantity',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      return true;
    } else {
      totalAmount.value -= (item['price'] as num).toDouble() * currentQtyInCart;
      cartItems.removeAt(index);
      return true;
    }
  }

  Future<Map<String, dynamic>?> processCheckout(BuildContext context, String? selectedCustomer) async {
    if (cartItems.isEmpty) return null;

    final authController = Get.find<AuthController>();
    double discountPercent = 0.0;
    
    if (selectedCustomer != null) {
      final customers = await _dbHelper.getCustomers(adminId: authController.adminId);
      final customer = customers.firstWhereOrNull((c) => c.name == selectedCustomer);
      if (customer != null) {
        discountPercent = customer.discount ?? 0.0;
      }
    }
    
    double subtotal = totalAmount.value;
    double discountAmount = (subtotal * discountPercent) / 100;
    
    // Redemption Values (Converted to Currency)
    double pointsValue = 0.0;
    final rules = LoyaltyService.to.currentRules;
    if (rules != null && pointsToRedeem.value > 0) {
      if (pointsToRedeem.value < 50) {
        Get.snackbar(
          'Minimum Points',
          'You need at least 50 points to redeem.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return null;
      }
      pointsValue = pointsToRedeem.value * rules.redemptionValuePerPoint; 
    }
    
    double finalTotal = subtotal - discountAmount - pointsValue - cashbackToUse.value;
    if (finalTotal < 0) finalTotal = 0;

    final sale = Sale(
      saleDate: DateTime.now(),
      totalAmount: finalTotal,
      adminId: authController.adminId, // Include adminId
      customerId: (selectedCustomer == null) ? null : selectedCustomerModel.value?.id,
    );
    
    final items = cartItems.map((item) => SaleItem(
      saleId: 0, 
      productId: item['id'] ?? 0,
      quantity: item['quantity'],
      unitPrice: (item['price'] as num).toDouble(),
      adminId: authController.adminId, // Include adminId
    )).toList();

    int saleId = await _dbHelper.insertSale(sale, items);
    
    // Process Loyalty Points/Cashback Update
    if (selectedCustomerModel.value != null && selectedCustomerModel.value!.id != null) {
      await LoyaltyService.to.processSaleLoyalty(
        customerId: selectedCustomerModel.value!.id!,
        billAmount: subtotal, // Earn based on subtotal before points redemption usually? Or final? Let's use subtotal.
        invoiceId: saleId,
        pointsRedeemed: pointsToRedeem.value,
        cashbackUsed: cashbackToUse.value,
      );
    }

    // Trigger sync to Supabase
    SupabaseService().syncData();

    // Refresh products to update quantities after deduction
    await _loadProducts();

    final completedSale = Sale(
      id: saleId,
      saleDate: sale.saleDate,
      totalAmount: sale.totalAmount,
      adminId: authController.adminId,
    );

    Get.snackbar(
      'Success',
      'Checkout processed successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    final cartCopy = List<Map<String, dynamic>>.from(cartItems);
    
    cartItems.clear();
    totalAmount.value = 0.0;
    selectedCustomerModel.value = null;
    loyaltyAccount.value = null;
    pointsToRedeem.value = 0.0;
    cashbackToUse.value = 0.0;
    
    return {
      'sale': completedSale, 
      'items': cartCopy, 
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'pointsRedeemed': pointsToRedeem.value,
      'cashbackUsed': cashbackToUse.value,
      'pointsEarned': LoyaltyService.to.calculatePoints(subtotal),
    };
  }

  void setIsScanning(bool value) {
    isScanning.value = value;
  }
}
