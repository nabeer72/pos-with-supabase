import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
          // Match QR code to product name; adjust if using IDs
          final product = products.firstWhere((p) => p['name'] == scannedCode);
          onProductFound(product);
        } catch (e) {
          onError('Product not found for QR code: $scannedCode');
        }
        return; // Process only the first valid barcode
      }
    }
  }
}

// Controller to handle business logic for NewSaleScreen
class NewSaleController {
  final List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0.0;
  bool _isScanning = false;
  late QRScannerService _qrScannerService;

  // Sample product data
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Product A',
      'price': 29.99,
      'category': 'Electronics',
      'icon': Icons.devices,
   
    },
    {
      'name': 'Product B',
      'price': 19.99,
      'category': 'Clothing',
      'icon': Icons.checkroom,

    },
    {
      'name': 'Product C',
      'price': 49.99,
      'category': 'Electronics',
      'icon': Icons.devices,
    
    },
    {
      'name': 'Product D',
      'price': 9.99,
      'category': 'Accessories',
      'icon': Icons.watch,
     
    },
    {
      'name': 'Product E',
      'price': 39.99,
      'category': 'Clothing',
      'icon': Icons.checkroom,
    
    },
    {
      'name': 'Product F',
      'price': 24.99,
      'category': 'Accessories',
      'icon': Icons.watch,
      
    },
  ];

  NewSaleController(BuildContext context) {
    _qrScannerService = QRScannerService(
      products: _products,
      onProductFound: (product) {
        addToCart(product);
        setIsScanning(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${product['name']} to cart via QR scan')),
        );
      },
      onError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setIsScanning(false);
      },
    );
  }

  List<Map<String, dynamic>> get cartItems => _cartItems;
  double get totalAmount => _totalAmount;
  bool get isScanning => _isScanning;
  QRScannerService get qrScannerService => _qrScannerService;
  List<Map<String, dynamic>> get products => _products;

  void addToCart(Map<String, dynamic> product) {
    _cartItems.add({...product, 'quantity': 1});
    _totalAmount += product['price'];
  }

  void updateQuantity(int index, int change) {
    final newQuantity = (_cartItems[index]['quantity'] as int) + change;
    if (newQuantity > 0) {
      _totalAmount += change * _cartItems[index]['price'];
      _cartItems[index]['quantity'] = newQuantity;
    } else {
      _totalAmount -= _cartItems[index]['price'] * _cartItems[index]['quantity'];
      _cartItems.removeAt(index);
    }
  }

  void processCheckout(BuildContext context, String? selectedCustomer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout processed successfully!')),
    );
    _cartItems.clear();
    _totalAmount = 0.0;
  }

  void setIsScanning(bool value) {
    _isScanning = value;
  }


}