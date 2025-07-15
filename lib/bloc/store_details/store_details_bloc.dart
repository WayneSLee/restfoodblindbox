// lib/bloc/store_details/store_details_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/models/product_model.dart'; // 引入 Product 模型
import 'package:restfoodblindbox/models/rating_model.dart'; // 引入 Rating 模型
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'store_details_event.dart';
import 'store_details_state.dart';

class StoreDetailsBloc extends Bloc<StoreDetailsEvent, StoreDetailsState> {
  final Store store;

  StoreDetailsBloc({required this.store}) : super(StoreDetailsInitial()) {
    on<StoreDetailsFetched>(_onStoreDetailsFetched);
  }

  Future<void> _onStoreDetailsFetched(
      StoreDetailsFetched event, Emitter<StoreDetailsState> emit) async {
    emit(StoreDetailsLoading());
    try {
      final results = await Future.wait([
        ApiService.fetchStoreRatings(event.storeId),
        ApiService.fetchProductsByStore(event.storeId),
      ]);

      // --- vvv 這是本次修正的核心 vvv ---
      // 使用 'as' 關鍵字進行明確的型別轉換
      final ratings = results[0] as List<Rating>;
      final products = results[1] as List<Product>;
      // --- ^^^ 修正到此結束 ^^^ ---

      emit(StoreDetailsLoaded(
        store: store,
        ratings: ratings,
        products: products,
      ));
    } catch (e) {
      emit(StoreDetailsError(e.toString()));
    }
  }
}