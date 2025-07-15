import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/cart_model.dart';
import 'package:restfoodblindbox/models/product_model.dart'; // 引入 Product model

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object> get props => [];
}

// 修改：加入購物車事件現在接收一個 Product 物件和 storeId
class CartItemAdded extends CartEvent {
  final Product product;
  final String storeId;
  final int quantity;

  const CartItemAdded(this.product, this.storeId, {this.quantity = 1});

  @override
  List<Object> get props => [product, storeId, quantity];
}

// 維持不變：移除商品事件
class CartItemRemoved extends CartEvent {
  final CartItem item; // <--- 將 Product 改回 CartItem
  const CartItemRemoved(this.item);

  @override
  List<Object> get props => [item];
}


// 新增：清空購物車事件
class CartCleared extends CartEvent {}

// 增加購物車中某個商品的數量
class CartItemQuantityIncreased extends CartEvent {
  final int productId;
  const CartItemQuantityIncreased(this.productId);

  @override
  List<Object> get props => [productId];
}

// 減少購物車中某個商品的數量
class CartItemQuantityDecreased extends CartEvent {
  final int productId;
  const CartItemQuantityDecreased(this.productId);

  @override
  List<Object> get props => [productId];
}