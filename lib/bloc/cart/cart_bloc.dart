import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/cart/cart_event.dart';
import 'package:restfoodblindbox/bloc/cart/cart_state.dart';
import 'package:restfoodblindbox/models/cart_model.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartLoaded()) {
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartCleared>(_onCartCleared);
    on<CartItemQuantityIncreased>(_onCartItemQuantityIncreased);
    on<CartItemQuantityDecreased>(_onCartItemQuantityDecreased);
  }

  void _onCartItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final currentState = state as CartLoaded;

    // 檢查是否為跨店購物
    if (currentState.storeId != null && currentState.storeId != event.storeId) {
      // 理想情況下，應該跳出提示框詢問使用者是否要清空購物車並加入新商品
      // MVP 階段，我們先簡單地清空舊購物車
      emit(CartLoaded(storeId: event.storeId));
      // 再次呼叫 add，將商品加入新的購物車
      add(event);
      return;
    }

    // 建立新的購物車列表
    final List<CartItem> updatedItems = List.from(currentState.items);

    try {
      // 檢查商品是否已存在
      final index = updatedItems.indexWhere((item) => item.productId == event.product.id);
      if (index != -1) {
        // 如果存在，更新數量
        updatedItems[index].quantity += event.quantity;
      } else {
        // 如果不存在，加入新商品
        updatedItems.add(CartItem(
          productId: event.product.id,
          storeId: event.storeId,
          name: event.product.name,
          price: event.product.price,
          quantity: event.quantity,
        ));
      }
      // 發出包含新列表和店家ID的 CartLoaded 狀態
      emit(CartLoaded(items: updatedItems, storeId: event.storeId));
    } catch (e) {
      // 可選：處理錯誤狀態
    }
  }

  void _onCartItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final currentState = state as CartLoaded;
    final List<CartItem> updatedItems = List.from(currentState.items)
    // 使用傳入的 CartItem 的 productId 來進行比對
      ..removeWhere((item) => item.productId == event.item.productId);

    final newStoreId = updatedItems.isEmpty ? null : currentState.storeId;

    emit(CartLoaded(items: updatedItems, storeId: newStoreId));
  }

  void _onCartCleared(CartCleared event, Emitter<CartState> emit) {
    // 發出一個全新的、空的 CartLoaded 狀態，代表購物車被清空
    emit(CartLoaded());
  }

  void _onCartItemQuantityIncreased(CartItemQuantityIncreased event, Emitter<CartState> emit) {
    final state = this.state as CartLoaded;
    final updatedItems = state.items.map((item) {
      if (item.productId == event.productId) {
        // TODO: 理想情況下，這裡也應該檢查庫存上限
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onCartItemQuantityDecreased(CartItemQuantityDecreased event, Emitter<CartState> emit) {
    final state = this.state as CartLoaded;
    final List<CartItem> updatedItems = [];

    for (final item in state.items) {
      if (item.productId == event.productId) {
        if (item.quantity > 1) {
          // 如果數量大於 1，則減 1
          updatedItems.add(item.copyWith(quantity: item.quantity - 1));
        }
        // 如果數量等於 1，則不加入新列表，等同於移除
      } else {
        updatedItems.add(item);
      }
    }

    final newStoreId = updatedItems.isEmpty ? null : state.storeId;
    emit(state.copyWith(items: updatedItems, storeId: newStoreId));
  }
}
