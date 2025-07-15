// lib/bloc/store_details/store_details_state.dart
import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/product_model.dart'; // 1. 引入 Product 模型
import 'package:restfoodblindbox/models/rating_model.dart';
import 'package:restfoodblindbox/models/store_model.dart';

abstract class StoreDetailsState extends Equatable {
  const StoreDetailsState();

  @override
  List<Object> get props => [];
}

class StoreDetailsInitial extends StoreDetailsState {}

class StoreDetailsLoading extends StoreDetailsState {}

class StoreDetailsLoaded extends StoreDetailsState {
  final Store store;
  final List<Rating> ratings;
  final List<Product> products; // 2. 新增商品列表欄位

  const StoreDetailsLoaded({
    required this.store,
    required this.ratings,
    required this.products, // 3. 在建構子中加入
  });

  @override
  List<Object> get props => [store, ratings, products]; // 4. 加入 props 中以便比較
}

class StoreDetailsError extends StoreDetailsState {
  final String message;

  const StoreDetailsError(this.message);

  @override
  List<Object> get props => [message];
}