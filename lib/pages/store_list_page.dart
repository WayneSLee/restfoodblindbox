import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restfoodblindbox/bloc/store/store_bloc.dart';
import 'package:restfoodblindbox/bloc/store/store_event.dart';
import 'package:restfoodblindbox/bloc/store/store_state.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/pages/map_page.dart';
import 'package:restfoodblindbox/pages/store_detail_page.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';
import 'package:restfoodblindbox/widgets/store_card.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  @override
  void initState() {
    super.initState();
    // 在頁面初始化時，觸發一次獲取店家的事件
    context.read<StoreBloc>().add(StoresFetched());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<StoreBloc, StoreState>(
        builder: (context, state) {
          if (state is StoreLoading || state is StoreInitial) {
            return const CustomLoadingIndicator();
          }
          if (state is StoreError) {
            return Center(child: Text(state.message));
          }
          if (state is StoreLoaded) {
            final topRatedStores = state.stores
                .where((store) => store.rating >= 4.5)
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StoreBloc>().add(StoresFetched());
              },
              child: CustomScrollView(
                slivers: [
                  if (topRatedStores.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalStoreSection(
                        context: context,
                        title: '✨ 好評店家推薦',
                        stores: topRatedStores,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        '🏘️ 附近所有店家',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final store = state.stores[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: StoreCard(
                              store: store,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StoreDetailPage(store: store),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: state.stores.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const MapPage(),
            ));
          },
          label: const Text('地圖模式'),
          icon: const Icon(Icons.map),
        ),
      ),
    );
  }

  Widget _buildHorizontalStoreSection({
    required BuildContext context,
    required String title,
    required List<Store> stores,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: StoreCard(
                    store: store,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailPage(store: store),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}