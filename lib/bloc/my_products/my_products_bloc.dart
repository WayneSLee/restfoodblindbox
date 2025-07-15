import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/my_products/my_products_event.dart';
import 'package:restfoodblindbox/bloc/my_products/my_products_state.dart';
import 'package:restfoodblindbox/services/api_service.dart';

class MyProductsBloc extends Bloc<MyProductsEvent, MyProductsState> {
  MyProductsBloc() : super(MyProductsInitial()) {
    on<MyProductsFetched>(_onMyProductsFetched);
  }

  Future<void> _onMyProductsFetched(MyProductsFetched event, Emitter<MyProductsState> emit) async {
    emit(MyProductsLoading());
    try {
      // 改回呼叫正式的 ApiService 方法
      final products = await ApiService.fetchProductsByStore(event.storeId);
      emit(MyProductsLoaded(products));
    } catch (e) {
      emit(MyProductsError(e.toString()));
    }
  }
}
