import 'package:equatable/equatable.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();
  @override
  List<Object> get props => [];
}

class StoresFetched extends StoreEvent {}