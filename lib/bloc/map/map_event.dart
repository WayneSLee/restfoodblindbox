import 'package:equatable/equatable.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

// 事件：當地圖頁面初次載入時觸發
class MapLoaded extends MapEvent {}