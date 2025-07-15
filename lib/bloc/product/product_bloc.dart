import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/product/product_event.dart';
import 'package:restfoodblindbox/bloc/product/product_state.dart';
import 'package:restfoodblindbox/services/api_service.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    on<ProductsFetched>(_onProductsFetched);
  }

  Future<void> _onProductsFetched(ProductsFetched event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      // 使用新的 ApiService 方法
      final products = await ApiService.fetchProductsByStore(event.storeId);
      emit(ProductLoaded(products));
    } catch (e) {
      print('[ProductBloc] API呼叫失敗，捕捉到的詳細錯誤: $e');
      emit(ProductError(e.toString()));
    }
  }
}