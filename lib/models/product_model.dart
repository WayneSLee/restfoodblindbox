import 'dart:convert';

// 將 JSON 字串轉換為 Product 列表的輔助函式
List<Product> productFromJson(String str) => List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final int quantity;
  // --- vvv 這是本次新增的欄位 vvv ---
  final String? pickupStartTime; // 可為空的自取開始時間
  final String? pickupEndTime;   // 可為空的自取結束時間
  // --- ^^^ 新增到此結束 ^^^ ---

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.quantity,
    // --- vvv 這是本次新增的欄位 vvv ---
    this.pickupStartTime,
    this.pickupEndTime,
    // --- ^^^ 新增到此結束 ^^^ ---
  });

  /// 一個工廠建構子 (Factory Constructor)，用於從 JSON map 建立 Product 物件
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"] ?? 0,
      name: json["name"] ?? '',
      price: (json["price"] as num?)?.toDouble() ?? 0.0,
      description: json["description"] ?? '',
      imageUrl: json["imageUrl"] ?? '',
      quantity: (json["quantity"] as num?)?.toInt() ?? 0,
      // --- vvv 這是本次新增的欄位 vvv ---
      pickupStartTime: json["pickupStartTime"], // 從 JSON 解析
      pickupEndTime: json["pickupEndTime"],     // 從 JSON 解析
      // --- ^^^ 新增到此結束 ^^^ ---
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: "$name", price: $price, quantity: $quantity)';
  }
}