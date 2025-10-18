import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos/Services/Controllers/report_controller.dart';
import 'package:pos/widgets/sales_card.dart';
import 'dart:math' show max;

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.deepOrangeAccent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final ReportController controller = Get.put(ReportController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Sales Reports',
          style: TextStyle(
            fontSize: (isLargeScreen ? 22.0 : screenWidth * 0.05).clamp(16.0, 24.0),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.fetchReportData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.deepOrangeAccent));
        }
        if (controller.salesData.isEmpty) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(controller),
              const SizedBox(height: 20),
              SalesAndTransactionsWidget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                salesData: {
                  'amount': controller.summary['totalAmount'] ?? 0.0,
                  'transactionCount': controller.summary['totalCount'] ?? 0,
                },
              ),
              const SizedBox(height: 24),
              _buildSalesChart(controller, screenWidth, screenHeight),
            ],
          ),
        );
      }),
    );
  }

  /// 🔸 Period Selector Chips
  Widget _buildPeriodSelector(ReportController controller) {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final isSelected = controller.selectedPeriod.value == periods[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => controller.changePeriod(periods[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepOrangeAccent : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepOrangeAccent),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.deepOrangeAccent.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  periods[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 📊 Sales Chart (Bar Chart)
  Widget _buildSalesChart(ReportController controller, double screenWidth, double screenHeight) {
    final data = controller.salesData;
    if (data.isEmpty) {
      return Container(
        height: (screenHeight * 0.4).clamp(200.0, 300.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: const Center(
          child: Text(
            'No chart data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    double maxY = (data.map((d) => (d['amount'] as num?)?.toDouble() ?? 0.0).reduce(max) * 1.2);

    return Container(
      height: (screenHeight * 0.45).clamp(220.0, 350.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.selectedPeriod.value} Sales Overview',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipColor: (_) => Colors.deepOrangeAccent.withOpacity(0.85),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[groupIndex];
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(2)}\n${item['date']}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return SideTitleWidget(
                            meta: meta,
                            angle: 40 * 3.1416 / 180, // slight rotation for better fit
                            space: 6,
                            child: Text(
                              data[index]['date']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (item['amount'] as num?)?.toDouble() ?? 0.0,
                        gradient: LinearGradient(
                          colors: [Colors.deepOrangeAccent, Colors.orangeAccent.shade100],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: (screenWidth / data.length / 2).clamp(10.0, 20.0),
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 600),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
