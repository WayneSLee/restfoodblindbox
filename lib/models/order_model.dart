import 'dart:convert';
import 'package:restfoodblindbox/models/customer_profile_model.dart';

// 將 JSON 字串轉換為 Order 列表的輔助函式
List<Order> ordersFromJson(String str) => List<Order>.from(json.decode(str).map((x) => Order.fromJson(x)));

// --- OrderItem class (維持不變) ---
class OrderItem {
  final int productId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '商品名稱未知',
      price: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
    );
  }
}

// --- Order class (修改處) ---
class Order {
  final String id;
  final String storeId;
  final String storeName;
  final String storeAddress; // <--- 新增店家地址欄位
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final List<OrderItem> items;
  final bool isRatedByConsumer;
  final bool isRatedByStore;
  final CustomerProfile? customerProfile;

  Order({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.storeAddress, // <--- 在建構子中加入
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
    required this.isRatedByConsumer,
    required this.isRatedByStore,
    this.customerProfile,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final storeData = json['store'] as Map<String, dynamic>?;

    return Order(
      id: json['id'].toString(),
      storeId: storeData?['storeId']?.toString() ?? '',
      storeName: storeData?['name'] ?? '店家名稱未知',
      storeAddress: storeData?['address'] ?? '地址未提供', // <--- 從 JSON 解析地址
      status: json['status'] ?? 'pending',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['orderDate'] != null
          ? DateTime.tryParse(json['orderDate']) ?? DateTime.now()
          : DateTime.now(),
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List)
          .map((itemJson) => OrderItem.fromJson(itemJson))
          .toList()
          : [],
      isRatedByConsumer: json['isRatedByConsumer'] ?? false,
      isRatedByStore: json['isRatedByStore'] ?? false,
      customerProfile: json['customerProfile'] != null
          ? CustomerProfile.fromJson(json['customerProfile'])
          : null,
    );
  }
}