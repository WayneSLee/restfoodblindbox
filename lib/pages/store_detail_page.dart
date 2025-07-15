import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restfoodblindbox/bloc/store_details/store_details_bloc.dart';
import 'package:restfoodblindbox/bloc/store_details/store_details_event.dart';
import 'package:restfoodblindbox/bloc/store_details/store_details_state.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';
import 'package:restfoodblindbox/widgets/product_list_item.dart';
import 'package:restfoodblindbox/widgets/rating_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// 將頁面改為 StatefulWidget
class StoreDetailPage extends StatefulWidget {
  final Store store;

  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  // 新增狀態變數來管理收藏狀態和 API 呼叫
  late bool _isFavorited;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    // 初始化時，使用從上一頁傳來的店家資料設定初始狀態
    _isFavorited = widget.store.isFavorited;
  }

  // 撥打電話
  Future<void> _callPhoneNumber(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('店家未提供電話號碼')),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法撥打電話至 $phoneNumber')),
        );
      }
    }
  }

  // 分享店家資訊
  void _shareStoreInfo(BuildContext context, Store store) {
    final String shareText =
        '嘿！我在「剩食盲盒」App 發現一家很棒的店，快來看看吧！\n\n店名：${store.name}\n地址：${store.address}';
    Share.share(shareText);
  }

  /// 處理收藏按鈕的點擊事件
  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      if (_isFavorited) {
        await ApiService.removeFavoriteStore(widget.store.id);
      } else {
        await ApiService.addFavoriteStore(widget.store.id);
      }
      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      StoreDetailsBloc(store: widget.store)..add(StoreDetailsFetched(widget.store.id)),
      child: Scaffold(
        body: BlocConsumer<StoreDetailsBloc, StoreDetailsState>(
          listener: (context, state) {
            // 當 BLoC 狀態更新時，同步本地的收藏狀態
            if (state is StoreDetailsLoaded) {
              if (mounted && _isFavorited != state.store.isFavorited) {
                setState(() {
                  _isFavorited = state.store.isFavorited;
                });
              }
            }
          },
          builder: (context, state) {
            if (state is StoreDetailsLoading || state is StoreDetailsInitial) {
              return const CustomLoadingIndicator();
            }

            if (state is StoreDetailsError) {
              return Center(child: Text('無法載入店家資訊: ${state.message}'));
            }

            if (state is StoreDetailsLoaded) {
              final loadedStore = state.store;
              final ratings = state.ratings;
              final products = state.products;

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<StoreDetailsBloc>()
                      .add(StoreDetailsFetched(widget.store.id));
                },
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(context, loadedStore),
                    SliverToBoxAdapter(
                      child: _buildStoreHeader(context, loadedStore),
                    ),
                    _buildSectionHeader(context, '🎁 剩食盲盒'),
                    products.isEmpty
                        ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Text('店家目前沒有任何盲盒'),
                        ),
                      ),
                    )
                        : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            return ProductListItem(
                              product: products[index],
                              storeId: loadedStore.id,
                            );
                          },
                          childCount: products.length,
                        ),
                      ),
                    ),
                    _buildSectionHeader(
                        context, '⭐ 顧客評價 (${ratings.length})'),
                    ratings.isEmpty
                        ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Text('目前還沒有任何評價'),
                        ),
                      ),
                    )
                        : SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return RatingCard(rating: ratings[index]);
                        },
                        childCount: ratings.length,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Store store) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      actions: [
        if (store.phone != null && store.phone!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _callPhoneNumber(context, store.phone),
            tooltip: '撥打電話',
          ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareStoreInfo(context, store),
          tooltip: '分享店家',
        ),
        IconButton(
          icon: Icon(
            _isFavorited ? Icons.favorite : Icons.favorite_border,
            color: _isFavorited ? Colors.red : null,
          ),
          onPressed: _isTogglingFavorite ? null : _toggleFavorite,
          tooltip: '收藏店家',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(store.name,
            style: const TextStyle(shadows: [Shadow(blurRadius: 8.0)])),
        background: Image.network(
          store.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  Widget _buildStoreHeader(BuildContext context, Store store) {
    final bool isOpen = store.isOpen;
    final Color statusColor =
    isOpen ? Colors.green.shade700 : Colors.red.shade700;
    final String statusText = isOpen ? '營業中' : '休息中';
    final List<String> weekDayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final String daysOpenText =
    store.daysOpen.map((dayNum) => '週${weekDayNames[dayNum - 1]}').join('、');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: store.tags
                    .map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Theme.of(context).primaryColorDark,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                ))
                    .toList(),
              ),
            ),
          Text(store.description,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              RatingBarIndicator(
                rating: store.rating,
                itemBuilder: (context, index) =>
                const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 24.0,
              ),
              const SizedBox(width: 8),
              Text(
                '${store.rating.toStringAsFixed(1)} / 5.0',
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            store.address,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(store.latitude, store.longitude),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(store.id),
                    position: LatLng(store.latitude, store.longitude),
                  ),
                },
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(width: 8),
              if (store.openingTime != null && store.closingTime != null)
                Expanded(
                  child: Text(
                    '(${store.openingTime} - ${store.closingTime})',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (daysOpenText.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    daysOpenText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}