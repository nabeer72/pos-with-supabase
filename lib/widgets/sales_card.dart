import 'package:flutter/material.dart';
import 'package:pos/widgets/currency_text.dart';

class SalesAndTransactionsWidget extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final String title;
  final Map<String, dynamic> salesData;

  const SalesAndTransactionsWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.title,
    required this.salesData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all((screenWidth * 0.04).clamp(12.0, 20.0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSalesColumn(context),
            _buildTransactionColumn(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        CurrencyText(
          price: salesData['amount'] is num ? (salesData['amount'] as num).toDouble() : 0.0,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Transactions',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(
          '${salesData['transactionCount'] ?? '0'}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
