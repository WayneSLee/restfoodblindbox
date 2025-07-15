import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object> get props => [];
}

class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrderLoaded extends OrderState {
  final List<Order> orders;
  const OrderLoaded(this.orders);
}
class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
}