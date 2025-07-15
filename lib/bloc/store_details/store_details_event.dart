// lib/bloc/store_details/store_details_event.dart
import 'package:equatable/equatable.dart';

abstract class StoreDetailsEvent extends Equatable {
  const StoreDetailsEvent();

  @override
  List<Object> get props => [];
}

class StoreDetailsFetched extends StoreDetailsEvent {
  final String storeId;

  const StoreDetailsFetched(this.storeId);

  @override
  List<Object> get props => [storeId];
}