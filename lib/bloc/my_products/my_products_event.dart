import 'package:equatable/equatable.dart';

abstract class MyProductsEvent extends Equatable {
  const MyProductsEvent();
  @override
  List<Object> get props => [];
}

class MyProductsFetched extends MyProductsEvent {
  final String storeId;
  const MyProductsFetched(this.storeId);
}