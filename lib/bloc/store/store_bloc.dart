import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:restfoodblindbox/bloc/store/store_event.dart';
import 'package:restfoodblindbox/bloc/store/store_state.dart';
import 'package:restfoodblindbox/services/api_service.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  StoreBloc() : super(StoreInitial()) {
    on<StoresFetched>(_onStoresFetched);
  }

  Future<void> _onStoresFetched(
      StoresFetched event, Emitter<StoreState> emit) async {
    emit(StoreLoading());
    try {
      // 2. 獲取使用者目前位置
      final position = await _determinePosition();

      // 3. 帶上座標呼叫 API
      final stores = await ApiService.fetchStores(
        userLat: position.latitude,
        userLon: position.longitude,
      );
      emit(StoreLoaded(stores));
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  // 4. 加入與 MapBloc 中完全一樣的定位功能方法
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('定位服務已關閉。');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('定位權限已被拒絕。');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('定位權限已被永久拒絕，我們無法請求權限。');
    }

    return await Geolocator.getCurrentPosition();
  }
}