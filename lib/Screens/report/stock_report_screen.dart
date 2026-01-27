import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pos/Services/Controllers/stock_report_controller.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:pos/widgets/currency_text.dart';

class AppColors {
  static const Color gradientStart = Color(0xFF1E3A8A);
  static const Color gradientEnd = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
}

class StockReportScreen extends StatelessWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockReportController controller = Get.put(StockReportController());

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: Get.back,
            ),
            title: const Text(
              'Stock Reports',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.fetchStockData,
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: () => _generatePdf(controller, isPrint: true),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _generatePdf(controller, isPrint: false),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.stockItems.isEmpty) {
          return const Center(
            child: Text(
              'No stock data available',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.stockItems.length,
          itemBuilder: (context, index) {
            final item = controller.stockItems[index];
            final isLowStock = item.quantity < 5;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLowStock ? Colors.red[100] : Colors.blue[100],
                  child: Icon(
                    item.icon,
                    color: isLowStock ? Colors.red : Colors.blue,
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Category: ${item.category}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isLowStock ? Colors.red : Colors.black87,
                      ),
                    ),
                    if (isLowStock)
                      const Text(
                        'Low Stock',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _generatePdf(StockReportController controller, {required bool isPrint}) async {
    try {
      final pdf = pw.Document();
      final stockData = controller.stockItems;
      final currencySymbol = CurrencyService().getCurrencySymbolSync();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Stock Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateTime.now().toString().split('.')[0],
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('Product Name', isHeader: true),
                      _buildTableCell('Category', isHeader: true),
                      _buildTableCell('Qty', isHeader: true),
                      _buildTableCell('Price ($currencySymbol)', isHeader: true),
                    ],
                  ),
                  ...stockData.map((item) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(item.name),
                        _buildTableCell(item.category),
                        _buildTableCell(item.quantity.toString()),
                        _buildTableCell(item.price.toStringAsFixed(2)),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total Products: ${stockData.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ];
          },
        ),
      );

      if (isPrint) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Stock_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } else {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'Stock_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Export Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }
}
