import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object> get props => [];
}

class ProductsFetched extends ProductEvent {
  final String storeId;
  const ProductsFetched(this.storeId);

  @override
  List<Object> get props => [storeId];
}