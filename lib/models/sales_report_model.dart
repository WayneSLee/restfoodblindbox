import 'dart:convert';

// 將 JSON 字串轉換為 SalesReport 物件的輔助函式
SalesReport salesReportFromJson(String str) => SalesReport.fromJson(json.decode(str));

class SalesReport {
  final String period;
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final List<TopSellingItem> topSellingItems;

  SalesReport({
    required this.period,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.topSellingItems,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    period: json["period"] ?? 'N/A',
    totalRevenue: (json["totalRevenue"] as num?)?.toDouble() ?? 0.0,
    totalOrders: (json["totalOrders"] as num?)?.toInt() ?? 0,
    averageOrderValue: (json["averageOrderValue"] as num?)?.toDouble() ?? 0.0,
    topSellingItems: json["topSellingItems"] != null
        ? List<TopSellingItem>.from(
        json["topSellingItems"].map((x) => TopSellingItem.fromJson(x)))
        : [],
  );
}

class TopSellingItem {
  final int productId;
  final String name;
  final int quantitySold;

  TopSellingItem({
    required this.productId,
    required this.name,
    required this.quantitySold,
  });

  factory TopSellingItem.fromJson(Map<String, dynamic> json) => TopSellingItem(
    productId: (json["productId"] as num?)?.toInt() ?? 0,
    name: json["name"] ?? '未知商品',
    quantitySold: (json["quantitySold"] as num?)?.toInt() ?? 0,
  );
}