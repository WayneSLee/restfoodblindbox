import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restfoodblindbox/bloc/map/map_bloc.dart';
import 'package:restfoodblindbox/bloc/map/map_event.dart';
import 'package:restfoodblindbox/bloc/map/map_state.dart';
import 'package:restfoodblindbox/pages/store_detail_page.dart';
import 'package:restfoodblindbox/bloc/product/product_bloc.dart';
import 'package:restfoodblindbox/pages/product_list.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 BlocProvider 來建立並提供 MapBloc
    return BlocProvider(
      create: (context) => MapBloc()..add(MapLoaded()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('探索附近的店家'),
        ),
        body: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            // 狀態一：正在載入或初始狀態
            if (state is MapLoading || state is MapInitial) {
              return const CustomLoadingIndicator();
            }

            // 狀態二：載入失敗
            if (state is MapFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('無法載入地圖：${state.error}', textAlign: TextAlign.center),
                ),
              );
            }

            // 狀態三：載入成功
            if (state is MapSuccess) {
              // 將店家列表轉換為地圖標記 (Set of Markers)
              final markers = state.stores.map((store) {
                // 現在 store 物件中已經有 latitude 和 longitude，
                // 我們可以直接使用它們來建立地圖標記的位置。
                return Marker(
                  markerId: MarkerId(store.id),
                  position: LatLng(store.latitude, store.longitude), // 使用真實座標
                  infoWindow: InfoWindow(
                    title: store.name,
                    // 我們可以顯示後端計算好的距離，讓資訊更豐富
                    snippet: '距離您約 ${store.distanceKm.toStringAsFixed(2)} 公里',
                    onTap: () {
                      // 導航到新的 StoreDetailPage，並把 store 物件傳過去
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailPage(store: store),
                        ),
                      );
                    },
                  ),
                );
              }).toSet();

              return GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: state.initialPosition,
                myLocationEnabled: true, // 顯示我的位置圖層
                myLocationButtonEnabled: true, // 顯示回到我位置的按鈕
                markers: markers,
              );
            }

            // 預設的 fallback 畫面
            return const Center(child: Text('發生未知錯誤'));
          },
        ),
      ),
    );
  }
}