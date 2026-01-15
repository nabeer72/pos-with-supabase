import 'package:flutter/material.dart';
import 'package:pos/Services/currency_service.dart';

/// A widget that displays a price with the current admin's currency symbol
class CurrencyText extends StatelessWidget {
  final double price;
  final TextStyle? style;
  final bool useSync;

  const CurrencyText({
    Key? key,
    required this.price,
    this.style,
    this.useSync = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (useSync) {
      // Use synchronous formatting (uses cached currency or default)
      return Text(
        CurrencyService().formatPriceSync(price),
        style: style,
      );
    }

    // Use asynchronous formatting (loads from database if needed)
    return FutureBuilder<String>(
      future: CurrencyService().formatPrice(price),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            '\$${price.toStringAsFixed(2)}', // Fallback while loading
            style: style,
          );
        }
        return Text(
          snapshot.data ?? '\$${price.toStringAsFixed(2)}',
          style: style,
        );
      },
    );
  }
}

/// A widget that displays just the currency symbol
class CurrencySymbol extends StatelessWidget {
  final TextStyle? style;

  const CurrencySymbol({
    Key? key,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: CurrencyService().getCurrencySymbol(),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? '\$',
          style: style,
        );
      },
    );
  }
}
