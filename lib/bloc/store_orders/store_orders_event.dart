import 'package:equatable/equatable.dart';

abstract class StoreOrdersEvent extends Equatable {
  const StoreOrdersEvent();
  @override
  List<Object> get props => [];
}

// 獲取店家訂單的事件
class StoreOrdersFetched extends StoreOrdersEvent {
  final String storeId;
  const StoreOrdersFetched(this.storeId);
}

// 店家接受訂單的事件
class StoreOrderAccepted extends StoreOrdersEvent {
  final String orderId;
  const StoreOrderAccepted(this.orderId);
}

// 店家拒絕訂單的事件
class StoreOrderRejected extends StoreOrdersEvent {
  final String orderId;
  const StoreOrderRejected(this.orderId);
}