import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos/Services/Controllers/analytics_controller.dart';
import 'package:pos/widgets/currency_text.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:pos/Services/currency_service.dart';

class AppColors {
  static const Color gradientStart = Color(0xFF1E3A8A);
  static const Color gradientEnd = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AnalyticsController controller = Get.put(AnalyticsController());
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
              'Business Analytics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.fetchAnalyticsData,
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(controller),
              const SizedBox(height: 24),
              _buildSectionTitle('Sales by Category'),
              _buildCategoryChart(controller, screenWidth),
              const SizedBox(height: 24),
              _buildSectionTitle('Monthly Sales Trend'),
              _buildMonthlyChart(controller, screenWidth),
              const SizedBox(height: 24),
              _buildSectionTitle('Top Performing Products'),
              _buildTopProductsList(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.gradientStart,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsController controller) {
    return Row(
      children: [
        _buildSummaryCard(
          'Sales',
          controller.totalSales.value,
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          'Expenses',
          controller.totalExpenses.value,
          Icons.trending_down,
          Colors.red,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          'Net Profit',
          controller.netProfit.value,
          Icons.account_balance_wallet,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: CurrencyText(
                price: value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(AnalyticsController controller, double screenWidth) {
    if (controller.salesByCategory.isEmpty) {
      return _buildEmptyChart('No category data available');
    }

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];

    for (int i = 0; i < controller.salesByCategory.length; i++) {
      final item = controller.salesByCategory[i];
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: (item['totalSales'] as num).toDouble(),
          title: '${item['category']}',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(AnalyticsController controller, double screenWidth) {
    if (controller.monthlyStats.isEmpty) {
      return _buildEmptyChart('No transaction history available');
    }

    final barGroups = <BarChartGroupData>[];
    double maxSales = 100;

    for (int i = 0; i < controller.monthlyStats.length; i++) {
      final sales = (controller.monthlyStats[i]['sales'] as num).toDouble();
      if (sales > maxSales) maxSales = sales;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: AppColors.gradientStart,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
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
      child: BarChart(
        BarChartData(
          maxY: maxSales * 1.2,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index < 0 || index >= controller.monthlyStats.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      controller.monthlyStats[index]['month'].toString().substring(5), // MM
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildTopProductsList(AnalyticsController controller) {
    if (controller.topProducts.isEmpty) {
      return const Center(child: Text('No sales data available'));
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
      child: Column(
        children: controller.topProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final isLast = index == controller.topProducts.length - 1;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gradientStart.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.gradientStart,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Qty Sold: ${product['totalQuantity']}'),
                trailing: CurrencyText(
                  price: (product['totalSales'] as num).toDouble(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }
}
