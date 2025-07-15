import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_bloc.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_event.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_state.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/pages/chat_page.dart';
import 'package:restfoodblindbox/pages/submit_rating_page.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';

final currencyFormatter =
NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0);
final dateFormatter = DateFormat('yyyy/MM/dd HH:mm');

class StoreOrdersPage extends StatelessWidget {
  final String storeId;
  const StoreOrdersPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StoreOrdersBloc()..add(StoreOrdersFetched(storeId)),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('訂單管理'),
            bottom: const TabBar(
              tabs: [
                Tab(text: '新進訂單'),
                Tab(text: '待取貨'),
                Tab(text: '歷史紀錄'),
              ],
            ),
          ),
          body: BlocConsumer<StoreOrdersBloc, StoreOrdersState>(
            listener: (context, state) {
              if (state is StoreOrderUpdateFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('操作失敗: ${state.message}'),
                      backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (state is StoreOrdersLoading || state is StoreOrdersInitial) {
                return const CustomLoadingIndicator();
              }
              if (state is StoreOrdersError) {
                return Center(child: Text('無法載入訂單: ${state.message}'));
              }
              if (state is StoreOrdersLoaded) {
                final pendingOrders = state.orders
                    .where((o) => o.status.toLowerCase() == 'pending')
                    .toList();
                final acceptedOrders = state.orders
                    .where((o) => o.status.toLowerCase() == 'accepted')
                    .toList();
                final historicalOrders = state.orders
                    .where((o) =>
                o.status.toLowerCase() == 'completed' ||
                    o.status.toLowerCase() == 'rejected')
                    .toList();

                return TabBarView(
                  children: [
                    _StoreOrderListView(
                      orders: pendingOrders,
                      storeId: state.storeId,
                      emptyMessage: '沒有需要處理的新訂單',
                      cardType: 'pending',
                    ),
                    _StoreOrderListView(
                      orders: acceptedOrders,
                      storeId: state.storeId,
                      emptyMessage: '沒有待取貨的訂單',
                      cardType: 'historical',
                    ),
                    _StoreOrderListView(
                      orders: historicalOrders,
                      storeId: state.storeId,
                      emptyMessage: '沒有歷史訂單紀錄',
                      cardType: 'historical',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _StoreOrderListView extends StatelessWidget {
  final List<Order> orders;
  final String storeId;
  final String emptyMessage;
  final String cardType;

  const _StoreOrderListView({
    required this.orders,
    required this.storeId,
    required this.emptyMessage,
    required this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async =>
            context.read<StoreOrdersBloc>().add(StoreOrdersFetched(storeId)),
        child: Stack(
          children: <Widget>[
            ListView(),
            Center(child: Text(emptyMessage)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<StoreOrdersBloc>().add(StoreOrdersFetched(storeId)),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return cardType == 'pending'
              ? IncomingOrderCard(order: order)
              : OrderHistoryCard(order: order, storeId: storeId);
        },
      ),
    );
  }
}

class IncomingOrderCard extends StatelessWidget {
  final Order order;
  const IncomingOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final displayOrderId =
    order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id;
    final customerProfile = order.customerProfile;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade700, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('訂單 #$displayOrderId',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[700])),
                Text(dateFormatter.format(order.createdAt.toLocal()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            if (customerProfile != null) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    customerProfile.name ?? '匿名顧客',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star,
                      size: 20, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '${customerProfile.averageRating.toStringAsFixed(1)} / 5.0 (${customerProfile.totalRatings} 則評價)',
                    style: const TextStyle(fontSize: 15),
                  )
                ],
              ),
              const Divider(height: 24),
            ],
            ...order.items
                .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text('${item.name} x ${item.quantity}',
                          overflow: TextOverflow.ellipsis)),
                  Text(currencyFormatter
                      .format(item.price * item.quantity)),
                ],
              ),
            ))
                .toList(),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('總計: ', style: TextStyle(fontSize: 16)),
              Text(currencyFormatter.format(order.totalPrice),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('聯絡顧客'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        orderId: order.id,
                        recipientName: order.customerProfile?.name ?? '顧客',
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('拒絕'),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('確認拒絕訂單'),
                            content: const Text('您確定要拒絕這筆訂單嗎？'),
                            actions: [
                              TextButton(
                                  child: const Text('取消'),
                                  onPressed: () =>
                                      Navigator.of(ctx).pop()),
                              TextButton(
                                  child: const Text('確定拒絕',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    context
                                        .read<StoreOrdersBloc>()
                                        .add(StoreOrderRejected(order.id));
                                  }),
                            ],
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('接受'),
                    onPressed: () {
                      context
                          .read<StoreOrdersBloc>()
                          .add(StoreOrderAccepted(order.id));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  final Order order;
  final String storeId;

  const OrderHistoryCard(
      {super.key, required this.order, required this.storeId});

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String label;
    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.blue;
        label = '已完成';
        break;
      case 'rejected':
        chipColor = Colors.red;
        label = '已拒絕';
        break;
      case 'accepted':
        chipColor = Colors.green;
        label = '待取貨';
        break;
      default:
        chipColor = Colors.grey;
        label = status;
    }
    return Chip(
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayOrderId =
    order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id;

    final bool canRate = order.status.toLowerCase() == 'completed';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('訂單 #$displayOrderId',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '總計: ${currencyFormatter.format(order.totalPrice)}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  dateFormatter.format(order.createdAt.toLocal()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (order.status.toLowerCase() != 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('聯絡顧客'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            orderId: order.id,
                            recipientName: order.customerProfile?.name ?? '顧客',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (canRate && !order.isRatedByStore)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.star_half_outlined),
                    label: const Text('評價顧客'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => SubmitRatingPage(
                            orderId: order.id,
                          ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          context
                              .read<StoreOrdersBloc>()
                              .add(StoreOrdersFetched(storeId));
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}