import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/product/product_bloc.dart';
import 'package:restfoodblindbox/bloc/product/product_event.dart';
import 'package:restfoodblindbox/bloc/product/product_state.dart';
import 'package:restfoodblindbox/widgets/product_card.dart';
import 'package:restfoodblindbox/widgets/product_card_skeleton.dart';
import 'package:restfoodblindbox/widgets/error_display_widget.dart';
import 'package:shimmer/shimmer.dart';

class ProductListPage extends StatelessWidget {
  final String storeId; // 接收店家 ID

  const ProductListPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    // 首次進入頁面時，向 ProductBloc 發送一次獲取商品的事件
    context.read<ProductBloc>().add(ProductsFetched(storeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品列表'),
      ),
      // 使用 BlocBuilder 來監聽 ProductBloc 的狀態變化
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          // 狀態一：正在載入或初始狀態時，顯示 Shimmer 骨架屏動畫
          if (state is ProductLoading || state is ProductInitial) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: 5, // 預先顯示 5 個佔位卡片
                itemBuilder: (context, index) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: ProductCardSkeleton(),
                  );
                },
              ),
            );
          }

          // 狀態二：商品載入成功時，顯示商品列表
          if (state is ProductLoaded) {
            if (state.products.isEmpty) {
              return const Center(child: Text('此店家目前沒有商品'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                // 👇 --- 這是我們修正的核心部分 --- 👇
                // 直接將整個 product 物件和 storeId 傳遞給 ProductCard
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ProductCard(
                    product: product,
                    storeId: storeId,
                  ),
                );
                // 👆 --- 修正完成 --- 👆
              },
            );
          }

          // 狀態三：載入失敗時，顯示錯誤與重試畫面
          if (state is ProductError) {
            return ErrorDisplayWidget(
              message: state.message,
              onRetry: () {
                // 當「重試」按鈕被點擊時，再次發送 ProductsFetched 事件
                context.read<ProductBloc>().add(ProductsFetched(storeId));
              },
            );
          }

          // 預設的 fallback 畫面，避免 UI 空白
          return const Center(child: Text('發生未知錯誤'));
        },
      ),
    );
  }
}
