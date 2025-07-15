import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/cart_model.dart';

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final String? storeId; // 記錄購物車所屬的店家 ID

  const CartLoaded({this.items = const <CartItem>[], this.storeId});

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  @override
  List<Object?> get props => [items, storeId];

  // 增加一個 copyWith 方法，方便在 BLoC 中更新狀態
  CartLoaded copyWith({List<CartItem>? items, String? storeId}) {
    return CartLoaded(
      items: items ?? this.items,
      storeId: storeId ?? this.storeId,
    );
  }
}
