import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapInitial()) {
    on<MapLoaded>(_onMapLoaded);
  }

  Future<void> _onMapLoaded(MapLoaded event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      // 1. 獲取使用者目前位置
      final Position position = await _determinePosition();

      // 2. 使用獲取到的位置，呼叫新的 fetchStores API
      final List<Store> stores = await ApiService.fetchStores(
        userLat: position.latitude,
        userLon: position.longitude,
      );

      // 3. 建立地圖的初始攝影機位置
      final CameraPosition initialPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.5,
      );

      // 4. 發出成功狀態，同時傳遞店家列表和初始位置
      emit(MapSuccess(stores: stores, initialPosition: initialPosition));
    } catch (e) {
      emit(MapFailure(e.toString()));
    }
  }

  /// 決定使用者的目前位置 (包含權限處理)
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