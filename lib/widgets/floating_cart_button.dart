import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/cart/cart_bloc.dart';
import 'package:restfoodblindbox/bloc/cart/cart_state.dart';
import 'package:restfoodblindbox/main.dart';

class FloatingCartButton extends StatelessWidget {
  const FloatingCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ValueListenableBuilder 來監聽我們全域的路由名稱變化
    return ValueListenableBuilder<String>(
      valueListenable: currentRouteName, // 監聽我們在 main.dart 中建立的變數
      builder: (context, routeName, child) {
        // 當購物車不為空，"且" 當前路由名稱不是 '/cart' 時，才顯示按鈕
        final bool showButton = routeName != '/cart';

        if (!showButton) {
          return const SizedBox.shrink(); // 不顯示按鈕
        }

        // 按鈕本身的邏輯不變，只是被包在了監聽器裡面
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoaded && state.items.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -12, end: -12),
                  badgeContent: Text(
                    state.items.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      navigatorKey.currentState?.pushNamed('/cart');
                    },
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}