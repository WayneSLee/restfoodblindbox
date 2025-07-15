import 'package:equatable/equatable.dart';
import 'package:restfoodblindbox/models/order_model.dart';

abstract class StoreOrdersState extends Equatable {
  const StoreOrdersState();
  @override
  List<Object> get props => [];
}

class StoreOrdersInitial extends StoreOrdersState {}
class StoreOrdersLoading extends StoreOrdersState {}
class StoreOrdersLoaded extends StoreOrdersState {
  final List<Order> orders;
  final String storeId;

  const StoreOrdersLoaded(this.orders, this.storeId);

  @override
  List<Object> get props => [orders, storeId];
}
class StoreOrdersError extends StoreOrdersState {
  final String message;
  const StoreOrdersError(this.message);
}
class StoreOrderUpdateInProgress extends StoreOrdersLoaded {
  const StoreOrderUpdateInProgress(super.orders, super.storeId);
}

// 訂單狀態更新成功
class StoreOrderUpdateSuccess extends StoreOrdersLoaded {
  const StoreOrderUpdateSuccess(super.orders, super.storeId);
}

// 訂單狀態更新失敗
class StoreOrderUpdateFailure extends StoreOrdersLoaded {
  final String message;
  const StoreOrderUpdateFailure(super.orders, super.storeId, this.message);
}