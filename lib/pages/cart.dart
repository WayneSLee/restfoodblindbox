import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/bloc/cart/cart_bloc.dart';
import 'package:restfoodblindbox/bloc/cart/cart_event.dart';
import 'package:restfoodblindbox/bloc/cart/cart_state.dart';
import 'package:restfoodblindbox/services/api_service.dart';

// 貨幣格式化工具
final formatter = NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$');

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // 用於控制「下單中...」讀取動畫的狀態變數
  bool _isPlacingOrder = false;

  /// 處理「確認下單」邏輯的方法
  Future<void> _placeOrder(BuildContext context, CartLoaded cartState) async {
    // 檢查購物車是否為空，或是否正在處理訂單，防止重複點擊
    if (_isPlacingOrder || cartState.items.isEmpty || cartState.storeId == null) {
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // 呼叫 ApiService 中的 createOrder 方法
      await ApiService.createOrder(cartState.storeId!, cartState.items);

      // 如果 mounted 屬性為 true，代表 Widget 仍在畫面上，可以安全地操作 context
      if (mounted) {
        // 顯示成功訊息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('訂單已成功送出！請至「我的訂單」頁面查看狀態。'),
            backgroundColor: Colors.green,
          ),
        );
        // 下單成功後，向 CartBloc 發送「清空購物車」的事件
        context.read<CartBloc>().add(CartCleared());
      }
    } catch (e) {
      if (mounted) {
        // 如果 API 呼叫失敗，顯示錯誤訊息
        print('[CartPage] 下單失敗，捕捉到的詳細錯誤: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下單失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 無論成功或失敗，最後都將讀取狀態設為 false
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('購物車')),
      // 使用 BlocBuilder 來監聽 CartBloc 的狀態變化並自動重建 UI
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          // 根據 state 的類型顯示不同的畫面
          if (state is CartInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartLoaded) {
            // 如果購物車是空的，顯示提示訊息
            if (state.items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('您的購物車是空的', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }
            // 如果購物車有商品，則顯示列表和結算資訊
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 商品列表
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  context.read<CartBloc>().add(CartItemQuantityDecreased(item.productId));
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  // TODO: 檢查庫存上限
                                  context.read<CartBloc>().add(CartItemQuantityIncreased(item.productId));
                                },
                              ),
                            ],
                          ),
                          trailing: Text(formatter.format(item.price * item.quantity)),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 32),
                  // 總計資訊
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('總計', style: TextStyle(fontSize: 20)),
                      Text(
                          formatter.format(state.totalPrice),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 下單按鈕或讀取動畫
                  _isPlacingOrder
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    // 只有購物車有商品時，按鈕才能點擊
                    onPressed: state.items.isNotEmpty ? () => _placeOrder(context, state) : null,
                    child: const Text('確認下單'),
                  ),
                ],
              ),
            );
          }
          // 如果是未定義的狀態，顯示通用錯誤訊息
          return const Center(child: Text('發生未知錯誤'));
        },
      ),
    );
  }
}
