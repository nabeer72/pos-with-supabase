class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
    };
  }

  // Create from Map
  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] as String,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
    );
  }

  @override
  String toString() => '$symbol ($code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class CurrencyList {
  // Comprehensive list of supported currencies
  static const List<Currency> currencies = [
    // Major Currencies
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    
    // South Asian Currencies
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    Currency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    Currency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
    Currency(code: 'NPR', symbol: 'Rs', name: 'Nepalese Rupee'),
    
    // Middle Eastern Currencies
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    Currency(code: 'SAR', symbol: 'ر.س', name: 'Saudi Riyal'),
    Currency(code: 'QAR', symbol: 'ر.ق', name: 'Qatari Riyal'),
    Currency(code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar'),
    Currency(code: 'BHD', symbol: 'د.ب', name: 'Bahraini Dinar'),
    Currency(code: 'OMR', symbol: 'ر.ع', name: 'Omani Rial'),
    Currency(code: 'ILS', symbol: '₪', name: 'Israeli Shekel'),
    Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    
    // Other Asian Currencies
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    Currency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    Currency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    
    // American Currencies
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    Currency(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso'),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    Currency(code: 'ARS', symbol: '\$', name: 'Argentine Peso'),
    Currency(code: 'CLP', symbol: '\$', name: 'Chilean Peso'),
    
    // Oceania Currencies
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
    
    // African Currencies
    Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
    Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
    
    // European Currencies (Non-Euro)
    Currency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
    Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
    Currency(code: 'PLN', symbol: 'zł', name: 'Polish Zloty'),
    Currency(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna'),
    Currency(code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint'),
    Currency(code: 'RON', symbol: 'lei', name: 'Romanian Leu'),
    Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    Currency(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia'),
  ];

  // Default currency
  static const Currency defaultCurrency = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
  );

  // Get currency by code
  static Currency? getCurrencyByCode(String code) {
    try {
      return currencies.firstWhere(
        (currency) => currency.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get currency or default
  static Currency getCurrencyByCodeOrDefault(String? code) {
    if (code == null || code.isEmpty) return defaultCurrency;
    return getCurrencyByCode(code) ?? defaultCurrency;
  }

  // Format price with currency
  static String formatPrice(double price, Currency currency) {
    return '${currency.symbol}${price.toStringAsFixed(2)}';
  }

  // Format price with currency code
  static String formatPriceWithCode(double price, String? currencyCode) {
    final currency = getCurrencyByCodeOrDefault(currencyCode);
    return formatPrice(price, currency);
  }
}
