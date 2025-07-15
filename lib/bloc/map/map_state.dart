import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restfoodblindbox/models/store_model.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

// 初始狀態
class MapInitial extends MapState {}

// 載入中狀態
class MapLoading extends MapState {}

// 載入成功狀態
class MapSuccess extends MapState {
  final List<Store> stores;
  final CameraPosition initialPosition;

  const MapSuccess({required this.stores, required this.initialPosition});

  @override
  List<Object?> get props => [stores, initialPosition];
}

// 載入失敗狀態
class MapFailure extends MapState {
  final String error;

  const MapFailure(this.error);

  @override
  List<Object?> get props => [error];
}