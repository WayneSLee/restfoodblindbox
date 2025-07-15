import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/product_model.dart';

abstract class MyProductsState extends Equatable {
  const MyProductsState();
  @override
  List<Object> get props => [];
}

class MyProductsInitial extends MyProductsState {}
class MyProductsLoading extends MyProductsState {}
class MyProductsLoaded extends MyProductsState {
  final List<Product> products;
  const MyProductsLoaded(this.products);
}
class MyProductsError extends MyProductsState {
  final String message;
  const MyProductsError(this.message);
}