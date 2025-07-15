import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/order/order_event.dart';
import 'package:restfoodblindbox/bloc/order/order_state.dart';
import 'package:restfoodblindbox/services/api_service.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc() : super(OrderInitial()) {
    on<OrdersFetched>(_onOrdersFetched);
  }

  Future<void> _onOrdersFetched(OrdersFetched event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      // 改回呼叫正式的 ApiService 方法
      final orders = await ApiService.fetchMyOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
