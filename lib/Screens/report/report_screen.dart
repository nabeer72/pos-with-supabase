import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pos/Services/Controllers/report_controller.dart';
import 'package:pos/widgets/sales_card.dart';
import 'package:pos/widgets/currency_text.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:pos/widgets/custom_loader.dart';

// COLORS
class AppColors {
  static const Color gradientStart = Color(0xFF1E3A8A);
  static const Color gradientEnd = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportController controller = Get.put(ReportController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,

      // APP BAR
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
              'Sales Reports',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                onPressed: () => _selectDateRange(context, controller),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.fetchReportData,
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

      // BODY
      body: SafeArea(
        child: Obx(() => controller.isLoading.value
            ? const Center(child: LoadingWidget())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(controller, screenWidth, isLandscape),
                    const SizedBox(height: 20),

                    if (controller.selectedPeriod.value == 'Custom')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: Text(
                            'Range: ${controller.customStartDate.value!.toString().split(' ')[0]} to ${controller.customEndDate.value!.toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.gradientStart),
                          ),
                        ),
                      ),

                    // SUMMARY
                    SalesAndTransactionsWidget(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      title: '${controller.selectedPeriod.value} Sales',
                      salesData: {
                        'amount': controller.summary['totalAmount'] ?? 0,
                        'transactionCount':
                            controller.summary['totalCount'] ?? 0,
                      },
                    ),

                    const SizedBox(height: 30),

                    _buildSalesChart(
                      controller,
                      screenWidth,
                      screenHeight,
                      isLandscape,
                    ),

                    const SizedBox(height: 30),

                    _buildSectionTitle('Detailed Transactions'),
                    const SizedBox(height: 12),
                    _buildDetailedList(controller),
                  ],
                ),
              )),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.gradientStart,
      ),
    );
  }

  // PERIOD SELECTOR
  Widget _buildPeriodSelector(
    ReportController controller,
    double screenWidth,
    bool isLandscape,
  ) {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

    return SizedBox(
      height: isLandscape ? screenWidth * 0.1 : screenWidth * 0.14,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (_, index) {
          final period = periods[index];

          return Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: Obx(() {
              final isSelected = controller.selectedPeriod.value == period;

              return GestureDetector(
                onTap: () => controller.changePeriod(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.gradientStart.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // SALES CHART
  Widget _buildSalesChart(
    ReportController controller,
    double screenWidth,
    double screenHeight,
    bool isLandscape,
  ) {
    final data = controller.salesData;

    if (data.isEmpty) {
      return _emptyChartWidget(screenHeight, isLandscape);
    }

    final values = data.map((e) => (e['amount'] as num?)?.toDouble() ?? 0).toList();
    final maxY = max(values.reduce(max).toDouble(), 100.0) * 1.2;

    return Container(
      height: isLandscape ? screenHeight * 0.7 : screenHeight * 0.45,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 5,
                getTitlesWidget: (value, _) => FutureBuilder<String>(
                  future: CurrencyService().getCurrencySymbol(),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? '\$'}${value.toInt()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.gradientStart.withOpacity(0.7),
                      ),
                    );
                  },
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  
                  final dateStr = data[i]['date']?.toString() ?? '';
                  String label = dateStr;

                  // Safely format label based on period
                  if (controller.selectedPeriod.value == 'Daily') {
                    if (dateStr.length >= 10) {
                       label = dateStr.substring(5, 10); // MM-DD
                    }
                  } else if (controller.selectedPeriod.value == 'Weekly') {
                     // Weekly format is usually YYYY-WW
                     if (dateStr.contains('-')) {
                        label = 'W${dateStr.split('-').last}';
                     }
                  } else if (controller.selectedPeriod.value == 'Monthly') {
                     if (dateStr.length >= 7) {
                        final monthNum = int.tryParse(dateStr.substring(5, 7));
                        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        if (monthNum != null && monthNum >= 1 && monthNum <= 12) {
                           label = monthNames[monthNum - 1];
                        } else {
                           label = dateStr.substring(5);
                        }
                     }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: values.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 16,
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailedList(ReportController controller) {
    if (controller.detailedSales.isEmpty) {
      return const Center(child: Text('No transactions for this period'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.detailedSales.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final sale = controller.detailedSales[index];
          final date = DateTime.tryParse(sale['saleDate'] ?? '');
          final formattedDate = date != null ? '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '-';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.gradientStart.withOpacity(0.1),
              child: const Icon(Icons.receipt_long, color: AppColors.gradientStart),
            ),
            title: Text(
              sale['customerName'] ?? 'Walk-in Customer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(formattedDate),
            trailing: CurrencyText(
              price: (sale['totalAmount'] as num).toDouble(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyChartWidget(double screenHeight, bool isLandscape) {
    return Container(
      height: isLandscape ? screenHeight * 0.6 : screenHeight * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'No sales data available',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, ReportController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.customStartDate.value != null && controller.customEndDate.value != null
          ? DateTimeRange(start: controller.customStartDate.value!, end: controller.customEndDate.value!)
          : null,
    );

    if (picked != null) {
      controller.setCustomRange(picked.start, picked.end);
    }
  }

  Future<void> _generatePdf(ReportController controller, {required bool isPrint}) async {
    try {
      final pdf = pw.Document();
      final salesData = controller.detailedSales;
      final summary = controller.summary;
      final currencySymbol = CurrencyService().getCurrencySymbolSync();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      controller.storeName.value,
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Detailed Sales Report',
                            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.Text(DateTime.now().toString().split('.')[0]),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Period: ${controller.selectedPeriod.value}'),
              if (controller.selectedPeriod.value == 'Custom')
                pw.Text('${controller.customStartDate.value!.toString().split(' ')[0]} to ${controller.customEndDate.value!.toString().split(' ')[0]}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Total Transactions: ${summary['totalCount']}'),
                   pw.Text('Total Amount: $currencySymbol ${summary['totalAmount']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _pdfCell('Date/Time', isHeader: true),
                      _pdfCell('Customer', isHeader: true),
                      _pdfCell('Amount', isHeader: true),
                    ],
                  ),
                  ...salesData.map((sale) {
                    return pw.TableRow(
                      children: [
                        _pdfCell(sale['saleDate']?.toString() ?? '-'),
                        _pdfCell(sale['customerName']?.toString() ?? 'Walk-in'),
                        _pdfCell('$currencySymbol ${(sale['totalAmount'] as num).toStringAsFixed(2)}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      if (isPrint) {
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      } else {
        await Printing.sharePdf(bytes: await pdf.save(), filename: 'Sales_Report_${DateTime.now().toIso8601String()}.pdf');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : null, fontSize: 10)),
    );
  }
}
