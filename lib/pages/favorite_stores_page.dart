import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/pages/store_detail_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';
import 'package:restfoodblindbox/widgets/store_card.dart';

// 1. 建立一個 StatefulWidget 來管理頁面狀態
class FavoriteStoresPage extends StatefulWidget {
  const FavoriteStoresPage({super.key});

  @override
  State<FavoriteStoresPage> createState() => _FavoriteStoresPageState();
}

class _FavoriteStoresPageState extends State<FavoriteStoresPage> {
  // 2. 使用 Future 來保存 API 的回傳結果
  late Future<List<Store>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    // 3. 在頁面初始化時，呼叫 API
    _favoritesFuture = ApiService.fetchFavoriteStores();
  }

  // 4. 提供一個下拉刷新的方法
  Future<void> _refreshFavorites() async {
    setState(() {
      _favoritesFuture = ApiService.fetchFavoriteStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFavorites,
        // 5. 使用 FutureBuilder 來根據 API 的執行狀態顯示不同的 UI
        child: FutureBuilder<List<Store>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            // 載入中
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomLoadingIndicator();
            }
            // 發生錯誤
            if (snapshot.hasError) {
              return Center(
                child: Text('無法載入收藏列表: ${snapshot.error}'),
              );
            }
            // 沒有資料或列表為空
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('您尚未收藏任何店家'),
              );
            }

            // 成功載入資料，顯示列表
            final favoriteStores = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteStores.length,
              itemBuilder: (context, index) {
                final store = favoriteStores[index];
                return StoreCard(
                  store: store,
                  onTap: () async {
                    // 點擊後跳轉到店家詳情頁
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreDetailPage(store: store),
                      ),
                    );
                    // 從詳情頁返回後，自動刷新一次，以同步收藏狀態
                    _refreshFavorites();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}