import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/my_products/my_products_bloc.dart';
import 'package:restfoodblindbox/bloc/my_products/my_products_event.dart';
import 'package:restfoodblindbox/bloc/my_products/my_products_state.dart';
import 'package:restfoodblindbox/pages/add_edit_product_page.dart'; // 我們稍後會建立這個頁面
import 'package:restfoodblindbox/services/api_service.dart';

class MyProductsPage extends StatelessWidget {
  final String storeId;
  const MyProductsPage({super.key, required this.storeId});

  // 重新整理商品列表的方法
  void _refreshProducts(BuildContext context) {
    context.read<MyProductsBloc>().add(MyProductsFetched(storeId));
  }

  @override
  Widget build(BuildContext context) {
    _refreshProducts(context); // 首次進入時載入

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的商品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              // 導航到新增頁面，並等待返回結果
              final bool? shouldRefresh = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => AddEditProductPage(storeId: storeId)),
              );
              // 如果返回 true，就重新整理列表
              if (shouldRefresh == true) {
                _refreshProducts(context);
              }
            },
            tooltip: '新增商品',
          ),
        ],
      ),
      body: BlocBuilder<MyProductsBloc, MyProductsState>(
        builder: (context, state) {
          // ... (Loading, Error 狀態不變) ...
          if (state is MyProductsLoaded) {
            // ...
            return ListView.builder(
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.brown, // 給一個背景色
                      child: Icon(
                        Icons.lunch_dining_outlined, // 使用一個食物相關的圖示
                        color: Colors.white,
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text('價格: \$${product.price.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            // 導航到編輯頁面
                            final bool? shouldRefresh = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => AddEditProductPage(storeId: storeId, productToEdit: product)),
                            );
                            if (shouldRefresh == true) {
                              _refreshProducts(context);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // 顯示確認對話框
                            final bool? confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('確認刪除'),
                                  content: Text('您確定要刪除「${product.name}」嗎？此操作無法復原。'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('取消'),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text('刪除'),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                );
                              },
                            );

                            // 如果使用者確認刪除，則呼叫 API
                            if (confirmDelete == true) {
                              try {
                                await ApiService.deleteProduct(product.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('商品已刪除')),
                                );
                                _refreshProducts(context); // 刪除成功後重新整理
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('刪除失敗: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          // ...
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
