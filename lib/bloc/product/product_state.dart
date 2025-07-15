import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/product_model.dart'; // 引入 Product model

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object> get props => [];
}

// 初始狀態
class ProductInitial extends ProductState {}

// 載入中狀態
class ProductLoading extends ProductState {}

// 載入成功狀態，包含商品列表
class ProductLoaded extends ProductState {
  final List<Product> products;
  const ProductLoaded(this.products);
  @override
  List<Object> get props => [products];
}

// 載入失敗狀態，包含錯誤訊息
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object> get props => [message];
}