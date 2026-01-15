import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/currency_model.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final _dbHelper = DatabaseHelper();
  
  // Current admin ID (should be set when user logs in)
  String? _currentAdminId;
  Currency? _currentCurrency;

  // Set current admin ID
  void setCurrentAdminId(String adminId) {
    _currentAdminId = adminId;
    _currentCurrency = null; // Reset currency when admin changes
  }

  // Get current admin ID
  String? get currentAdminId => _currentAdminId;

  // Load currency for current admin
  Future<Currency> loadCurrency() async {
    if (_currentAdminId == null) {
      return CurrencyList.defaultCurrency;
    }

    if (_currentCurrency != null) {
      return _currentCurrency!;
    }

    final currencyCode = await _dbHelper.getCurrency(adminId: _currentAdminId!);
    _currentCurrency = CurrencyList.getCurrencyByCodeOrDefault(currencyCode);
    return _currentCurrency!;
  }

  // Get current currency (cached)
  Future<Currency> getCurrentCurrency() async {
    if (_currentCurrency != null) {
      return _currentCurrency!;
    }
    return await loadCurrency();
  }

  // Set currency for current admin
  Future<void> setCurrency(Currency currency) async {
    if (_currentAdminId == null) {
      throw Exception('Admin ID not set. Please login first.');
    }

    await _dbHelper.setCurrency(currency.code, adminId: _currentAdminId!);
    _currentCurrency = currency;
  }

  // Set currency by code
  Future<void> setCurrencyByCode(String currencyCode) async {
    final currency = CurrencyList.getCurrencyByCodeOrDefault(currencyCode);
    await setCurrency(currency);
  }

  // Format price with current currency
  Future<String> formatPrice(double price) async {
    final currency = await getCurrentCurrency();
    return CurrencyList.formatPrice(price, currency);
  }

  // Format price synchronously (use cached currency or default)
  String formatPriceSync(double price) {
    final currency = _currentCurrency ?? CurrencyList.defaultCurrency;
    return CurrencyList.formatPrice(price, currency);
  }

  // Get currency symbol
  Future<String> getCurrencySymbol() async {
    final currency = await getCurrentCurrency();
    return currency.symbol;
  }

  // Get currency symbol synchronously
  String getCurrencySymbolSync() {
    return _currentCurrency?.symbol ?? CurrencyList.defaultCurrency.symbol;
  }

  // Get currency code
  Future<String> getCurrencyCode() async {
    final currency = await getCurrentCurrency();
    return currency.code;
  }

  // Initialize currency for a new admin (set default)
  Future<void> initializeCurrencyForAdmin(String adminId) async {
    final existingCurrency = await _dbHelper.getCurrency(adminId: adminId);
    if (existingCurrency == null) {
      await _dbHelper.setCurrency(CurrencyList.defaultCurrency.code, adminId: adminId);
    }
  }

  // Reset currency cache (useful when switching admins)
  void resetCache() {
    _currentCurrency = null;
  }
}
