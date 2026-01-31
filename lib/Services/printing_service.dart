import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pos/Services/models/sale_model.dart';
import 'package:intl/intl.dart';
import 'package:pos/Services/receipt_service.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:pos/Services/loyalty_service.dart';

class PrintingService {
  Future<void> printReceipt({
    required Sale sale,
    required List<Map<String, dynamic>> items,
    String? customerName,
    double? subtotal,
    double? discountAmount,
    double? discountPercent,
    double? pointsRedeemed,
    double? pointsEarned,
    double? cashbackUsed,
  }) async {
    final receiptService = ReceiptService();
    final settings = await receiptService.getReceiptSettings();
    final currency = await CurrencyService().getCurrentCurrency();
    final currencySymbol = '${currency.symbol} (${currency.code})';
    
    final pdf = pw.Document();

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt paper format
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(settings['store_name'] ?? 'POS SYSTEM', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              if (settings['store_address']?.isNotEmpty ?? false)
                pw.Center(child: pw.Text(settings['store_address']!)),
              if (settings['store_phone']?.isNotEmpty ?? false)
                pw.Center(child: pw.Text('Tel: ${settings['store_phone']!}')),
              pw.SizedBox(height: 10),
              pw.Text('Date: $dateStr'),
              pw.Text('Order ID: ${sale.id ?? 'New'}'),
              if (customerName != null) pw.Text('Customer: $customerName'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 20),
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(item['name'])),
                       pw.Text('${item['quantity']}'),
                       pw.SizedBox(width: 20),
                       pw.Text('${currency.symbol} ${(item['quantity'] * item['price']).toStringAsFixed(2)}'),
                     ],
                   ),
                 );
               }).toList(),
               pw.Divider(),
                if (subtotal != null && discountAmount != null && (discountAmount > 0)) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal:'),
                      pw.Text('${currency.symbol} ${subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount (${discountPercent?.toStringAsFixed(0)}%):'),
                      pw.Text('- ${currency.symbol} ${discountAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                if (pointsRedeemed != null && pointsRedeemed > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Points Redeemed ($pointsRedeemed):'),
                      pw.Text('- ${currency.symbol} ${(pointsRedeemed * (LoyaltyService.to.currentRules?.redemptionValuePerPoint ?? 0.5)).toStringAsFixed(2)}'),
                    ],
                  ),
                if (cashbackUsed != null && cashbackUsed > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Cashback Used:'),
                      pw.Text('- ${currency.symbol} ${cashbackUsed.toStringAsFixed(2)}'),
                    ],
                  ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL (${currency.code}):', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${currency.symbol} ${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                if (pointsEarned != null && pointsEarned > 0) ...[
                  pw.Divider(),
                  pw.Center(
                    child: pw.Text('Points Earned: ${pointsEarned.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text(settings['receipt_footer'] ?? 'Thank you for your business!')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
