import 'package:equatable/equatable.dart';

// 我們讓 CartItem 繼承 Equatable，這有助於 BLoC 更有效地比較物件
class CartItem extends Equatable {
  final int productId;   // 商品的唯一 ID
  final String storeId;   // 商品所屬的店家 ID
  final String name;      // 商品名稱
  final double price;     // 商品價格
  int quantity;           // 商品數量

  CartItem({
    required this.productId,
    required this.storeId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [productId, storeId, name, price, quantity];

  // 增加一個 copyWith 方法，方便我們在 BLoC 中更新數量
  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      storeId: storeId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}
