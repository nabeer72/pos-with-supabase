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
    final orientation = MediaQuery.of(context).orientation;
    final isLargeScreen = screenWidth > 900;
    final isLandscape = orientation == Orientation.landscape;

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(controller, screenWidth, isLandscape),
                  SizedBox(height: screenHeight * 0.02),
                  SalesAndTransactionsWidget(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    salesData: {
                      'amount': controller.summary['totalAmount'] ?? 0.0,
                      'transactionCount': controller.summary['totalCount'] ?? 0,
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  _buildSalesChart(
                    controller,
                    screenWidth,
                    screenHeight,
                    isLandscape,
                    constraints,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔸 Period Selector Chips
  Widget _buildPeriodSelector(
      ReportController controller, double screenWidth, bool isLandscape) {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    return SizedBox(
      height: isLandscape ? screenWidth * 0.08 : screenWidth * 0.12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final isSelected = controller.selectedPeriod.value == periods[index];
          return Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: GestureDetector(
              onTap: () => controller.changePeriod(periods[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: isLandscape ? screenWidth * 0.015 : screenWidth * 0.02,
                ),
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
                    fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
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
  Widget _buildSalesChart(
    ReportController controller,
    double screenWidth,
    double screenHeight,
    bool isLandscape,
    BoxConstraints constraints,
  ) {
    final data = controller.salesData;
    if (data.isEmpty) {
      return Container(
        height: isLandscape
            ? (screenHeight * 0.6).clamp(180.0, 250.0)
            : (screenHeight * 0.4).clamp(200.0, 300.0),
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
      height: isLandscape
          ? (screenHeight * 0.7).clamp(200.0, 300.0)
          : (screenHeight * 0.45).clamp(220.0, 350.0),
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
            style: TextStyle(
              fontSize: (screenWidth * 0.04).clamp(16.0, 18.0),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
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
                      reservedSize: isLandscape ? 50 : 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return SideTitleWidget(
                           meta: meta,
                            angle: isLandscape ? 45 * 3.1416 / 180 : 40 * 3.1416 / 180,
                            space: 6,
                            child: Text(
                              data[index]['date']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.025).clamp(10.0, 12.0),
                                color: Colors.black87,
                              ),
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
                      reservedSize: isLandscape ? 50 : 45,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.025).clamp(10.0, 12.0),
                          color: Colors.black87,
                        ),
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
                        width: (screenWidth / (data.length * (isLandscape ? 2.5 : 2))).clamp(8.0, 16.0),
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