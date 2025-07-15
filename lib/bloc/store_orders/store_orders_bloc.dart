import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_event.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_state.dart';
import 'package:restfoodblindbox/services/api_service.dart';

class StoreOrdersBloc extends Bloc<StoreOrdersEvent, StoreOrdersState> {
  StoreOrdersBloc() : super(StoreOrdersInitial()) {
    on<StoreOrdersFetched>(_onStoreOrdersFetched);
    on<StoreOrderAccepted>(_onStoreOrderAccepted);
    on<StoreOrderRejected>(_onStoreOrderRejected);
  }

  Future<void> _onStoreOrdersFetched(StoreOrdersFetched event, Emitter<StoreOrdersState> emit) async {
    emit(StoreOrdersLoading());
    try {
      final orders = await ApiService.fetchStoreOrders(event.storeId);
      emit(StoreOrdersLoaded(orders, event.storeId));
    } catch (e) {
      emit(StoreOrdersError(e.toString()));
    }
  }

  Future<void> _onStoreOrderAccepted(StoreOrderAccepted event, Emitter<StoreOrdersState> emit) async {
    final currentState = state;
    if (currentState is StoreOrdersLoaded) {
      // 1. 發出「更新中」狀態
      emit(StoreOrderUpdateInProgress(currentState.orders, currentState.storeId));
      try {
        await ApiService.acceptOrder(event.orderId);
        // 2. 為了顯示 SnackBar，先發出「成功」狀態
        emit(StoreOrderUpdateSuccess(currentState.orders, currentState.storeId));
        // 3. 接著立刻觸發一次重新整理，以獲取最新的列表
        add(StoreOrdersFetched(currentState.storeId));
      } catch (e) {
        // 4. 如果失敗，發出「失敗」狀態，並附上錯誤訊息
        emit(StoreOrderUpdateFailure(currentState.orders, currentState.storeId, e.toString()));
      }
    }
  }

  Future<void> _onStoreOrderRejected(StoreOrderRejected event, Emitter<StoreOrdersState> emit) async {
    final currentState = state;
    if (currentState is StoreOrdersLoaded) {
      emit(StoreOrderUpdateInProgress(currentState.orders, currentState.storeId));
      try {
        await ApiService.rejectOrder(event.orderId);
        emit(StoreOrderUpdateSuccess(currentState.orders, currentState.storeId));
        add(StoreOrdersFetched(currentState.storeId));
      } catch (e) {
        emit(StoreOrderUpdateFailure(currentState.orders, currentState.storeId, e.toString()));
      }
    }
  }
}
