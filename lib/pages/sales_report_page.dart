import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/models/sales_report_model.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';

class SalesReportPage extends StatefulWidget {
  final String storeId;
  const SalesReportPage({super.key, required this.storeId});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  late Future<SalesReport> _reportFuture;
  String _selectedPeriod = 'weekly'; // 預設顯示週報告

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() {
    setState(() {
      _reportFuture =
          ApiService.fetchSalesReport(widget.storeId, period: _selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('銷售報告'),
        actions: [
          // 讓店家可以切換時間區間
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              dropdownColor: Colors.blueGrey[700],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPeriod = newValue;
                    _fetchReport();
                  });
                }
              },
              items: <String>['weekly', 'monthly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'weekly' ? '本週' : '本月'),
                );
              }).toList(),
            ),
          )
        ],
      ),
      body: FutureBuilder<SalesReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('無法載入報告: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('目前沒有銷售數據'));
          }

          final report = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCards(report),
              const SizedBox(height: 24),
              _buildTopSellingChart(report.topSellingItems),
            ],
          );
        },
      ),
    );
  }

  // 建立頂部的數據總覽卡片
  Widget _buildSummaryCards(SalesReport report) {
    final currencyFormatter = NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard('總營業額', currencyFormatter.format(report.totalRevenue), Icons.attach_money),
        _buildSummaryCard('總訂單數', report.totalOrders.toString(), Icons.receipt_long),
        _buildSummaryCard('平均客單價', currencyFormatter.format(report.averageOrderValue), Icons.pie_chart),
        _buildSummaryCard('銷售品項數', report.topSellingItems.length.toString(), Icons.sell),
      ],
    );
  }

  // 單一數據卡片的 UI
  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)), // 縮小標題字體
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // 稍微縮小數值字體
                  overflow: TextOverflow.ellipsis, // 超出部分顯示省略符號
                  maxLines: 1, // 限制為一行
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 建立熱銷商品長條圖
  Widget _buildTopSellingChart(List<TopSellingItem> items) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('熱銷商品排行', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            items.elementAt(index).name, // 顯示完整商品名稱
                            style: const TextStyle(fontSize: 10), // 稍微縮小標籤字體
                            overflow: TextOverflow.ellipsis, // 超出部分顯示省略符號
                            maxLines: 1, // 限制為一行
                          ),
                        );
                      }
                      return const Text('');
                    }, reservedSize: 40)), // 增加底部預留空間
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [BarChartRodData(toY: item.quantitySold.toDouble(), color: Theme.of(context).primaryColor)],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}