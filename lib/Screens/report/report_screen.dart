import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pos/Services/Controllers/report_controller.dart';
import 'package:pos/widgets/sales_card.dart';

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
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.fetchReportData,
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: () => _printReport(controller),
              ),
            ],
          ),
        ),
      ),

      // BODY
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(controller, screenWidth, isLandscape),
              const SizedBox(height: 20),

              // SUMMARY
              Obx(() => SalesAndTransactionsWidget(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    salesData: {
                      'amount': controller.summary['totalAmount'] ?? 0,
                      'transactionCount':
                          controller.summary['totalCount'] ?? 0,
                    },
                  )),

              const SizedBox(height: 30),

              _buildSalesChart(
                controller,
                screenWidth,
                screenHeight,
                isLandscape,
              ),
            ],
          ),
        ),
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
              final isSelected =
                  controller.selectedPeriod.value == period;

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
                      color:
                          isSelected ? Colors.white : Colors.black,
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
    return Obx(() {
      final data = controller.salesData;

      if (data.isEmpty) {
        return _emptyChartWidget(screenHeight, isLandscape);
      }

      final values = data
          .map((e) => (e['amount'] as num?)?.toDouble() ?? 0)
          .toList();

      final maxY = max(values.reduce(max), 100) * 1.2;

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
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 5,
                  getTitlesWidget: (value, _) => Text(
                    'Rs. ${value.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          AppColors.gradientStart.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i >= data.length) return const SizedBox();
                    return Text(
                      data[i]['date'] ?? '',
                      style: const TextStyle(fontSize: 10),
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
                      colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                      ],
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
    });
  }

  // EMPTY STATE
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

  // =======================
  // PRINT PDF REPORT
  // =======================
Future<void> _printReport(ReportController controller) async {
  try {
    final pdf = pw.Document();

    // SAFETY CHECK
    final salesData = controller.salesData;
    final summary = controller.summary;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sales Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Period: ${controller.selectedPeriod.value}',
                style: const pw.TextStyle(fontSize: 14),
              ),

              pw.Divider(),

              pw.Text(
                'Total Sales: Rs. ${summary['totalAmount'] ?? 0}',
              ),
              pw.Text(
                'Total Transactions: ${summary['totalCount'] ?? 0}',
              ),

              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // DATA ROWS
                  ...salesData.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item['date']?.toString() ?? '-',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs. ${item['amount'] ?? 0}',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'Generated on: ${DateTime.now()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    // THIS LINE OPENS PREVIEW (MOST IMPORTANT)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  } catch (e) {
    Get.snackbar(
      'Print Error',
      e.toString(),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
}
