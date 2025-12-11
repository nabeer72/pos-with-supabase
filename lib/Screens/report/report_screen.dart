import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos/Services/Controllers/report_controller.dart';
import 'package:pos/widgets/sales_card.dart';
import 'dart:math' show max;

// EXACT SAME GRADIENT COLORS FROM PROFILE SCREEN
class AppColors {
  static const Color gradientStart = Color(0xFF1E3A8A); // Navy Blue
  static const Color gradientEnd   = Color(0xFF3B82F6); // Soft Blue
  static const Color accent        = Color(0xFF475569); // Slate Grey
  static const Color background    = Color(0xFFF8FAFC);
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.gradientStart,
      statusBarIconBrightness: Brightness.light,
    ));

    final ReportController controller = Get.put(ReportController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 900;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Sales Reports',
              style: TextStyle(
                fontSize: (isLargeScreen ? 24.0 : screenWidth * 0.05).clamp(16.0, 26.0),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.fetchReportData,
              ),
            ],
          ),
        ),
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
                  // Summary Card (auto-updates because controller.summary is Rx)
                  Obx(() => SalesAndTransactionsWidget(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        salesData: {
                          'amount': controller.summary['totalAmount'] ?? 0.0,
                          'transactionCount': controller.summary['totalCount'] ?? 0,
                        },
                      )),
                  SizedBox(height: screenHeight * 0.03),
                  _buildSalesChart(controller, screenWidth, screenHeight, isLandscape),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // FIXED: No GetX error + Text perfectly centered
 Widget _buildPeriodSelector(
  ReportController controller,
  double screenWidth,
  bool isLandscape,
) {
  final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  return SizedBox(
    height: isLandscape ? screenWidth * 0.10 : screenWidth * 0.14, // 🔥 Increased height
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final period = periods[index];

        return Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.03),

          child: Obx(() {
            final bool isSelected = controller.selectedPeriod.value == period;

            return GestureDetector(
              onTap: () => controller.changePeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
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

                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,

                      // ⭐ FIX: Always visible text
                      color: isSelected
                          ? Colors.white
                          : Colors.black, // 🔥 Dark color (always visible)

                      // ⭐ Enhancement for selected text visibility
                      shadows: isSelected
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              )
                            ]
                          : [],
                    ),
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


  // 100% CRASH-PROOF CHART – No RangeError, No Null Error
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

      final values = data.map((e) => (e['amount'] as num?)?.toDouble() ?? 0.0).toList();
      final maxAmount = values.isEmpty ? 0 : values.reduce(max);
      final maxY = maxAmount <= 0 ? 100.0 : maxAmount * 1.3;

      return Container(
        height: isLandscape ? screenHeight * 0.7 : screenHeight * 0.45,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${controller.selectedPeriod.value} Sales Overview',
              style: TextStyle(
                fontSize: (screenWidth * 0.045).clamp(16.0, 19.0),
                fontWeight: FontWeight.bold,
                color: AppColors.gradientStart,
              ),
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
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.all(12),
                      tooltipMargin: 8,
                      getTooltipColor: (_) => AppColors.gradientStart.withOpacity(0.95),
                      getTooltipItem: (group, _, rod, __) {
                        final i = group.x.toInt();
                        if (i < 0 || i >= data.length) return null;
                        final raw = data[i]['date']?.toString() ?? '';
                        final date = raw.length >= 10 ? raw.substring(5, 10).replaceAll('-', '/') : raw;
                        return BarTooltipItem(
                          '\$${rod.toY.toStringAsFixed(0)}\n$date',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox.shrink();

                          final raw = data[i]['date']?.toString() ?? '';
                          final date = raw.length >= 10 ? raw.substring(5, 10).replaceAll('-', '/') : raw;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              date,
                              style: TextStyle(
                                color: AppColors.gradientStart.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxY / 5,
                        getTitlesWidget: (value, meta) => Text(
                          '\$${value.toInt()}',
                          style: TextStyle(color: AppColors.gradientStart.withOpacity(0.7), fontSize: 11),
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
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: values.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          gradient: const LinearGradient(
                            colors: [AppColors.gradientStart, AppColors.gradientEnd],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: isLandscape ? 20 : 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOutCubic,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyChartWidget(double screenHeight, bool isLandscape) {
    return Container(
      height: isLandscape ? screenHeight * 0.6 : screenHeight * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 60, color: AppColors.gradientStart.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No sales data available',
              style: TextStyle(color: AppColors.gradientStart.withOpacity(0.6), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}