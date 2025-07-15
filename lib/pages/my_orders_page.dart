import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/bloc/order/order_bloc.dart';
import 'package:restfoodblindbox/bloc/order/order_event.dart';
import 'package:restfoodblindbox/bloc/order/order_state.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/pages/order_detail_page.dart';
import 'package:restfoodblindbox/pages/submit_rating_page.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: '待處理'),
              Tab(text: '待取貨'),
              Tab(text: '歷史紀錄'),
            ],
          ),
          title: const Text('我的訂單'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading || state is OrderInitial) {
              return const CustomLoadingIndicator();
            }
            if (state is OrderError) {
              return Center(child: Text('無法載入訂單: ${state.message}'));
            }
            if (state is OrderLoaded) {
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
                  _OrderListView(
                    orders: pendingOrders,
                    emptyMessage: '沒有待處理的訂單',
                  ),
                  _OrderListView(
                    orders: acceptedOrders,
                    emptyMessage: '沒有待取貨的訂單',
                  ),
                  _OrderListView(
                    orders: historicalOrders,
                    emptyMessage: '沒有歷史訂單紀錄',
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _OrderListView extends StatelessWidget {
  final List<Order> orders;
  final String emptyMessage;

  const _OrderListView({required this.orders, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<OrderBloc>().add(OrdersFetched());
        },
        child: Stack(
          children: <Widget>[
            ListView(),
            Center(child: Text(emptyMessage)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrderBloc>().add(OrdersFetched());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(order: order);
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        label = '待取貨';
        icon = Icons.qr_code;
        break;
      case 'completed':
        color = Colors.blue;
        label = '已完成';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = '已拒絕';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        label = '待處理';
        icon = Icons.hourglass_empty;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canRate = order.status.toLowerCase() == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(
                order: order,
                userRole: 'consumer',
              ),
            ),
          )
              .then((didPop) {
            if (didPop == true) {
              context.read<OrderBloc>().add(OrdersFetched());
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      order.storeName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const Divider(height: 20),
              ...order.items
                  .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${item.name} x ${item.quantity}',
                        style: TextStyle(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                          locale: 'zh_TW',
                          symbol: 'NT\$',
                          decimalDigits: 0)
                          .format(item.price * item.quantity),
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  ],
                ),
              ))
                  .toList(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm')
                        .format(order.createdAt.toLocal()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '總計: ${NumberFormat.currency(locale: 'zh_TW', symbol: 'NT\$', decimalDigits: 0).format(order.totalPrice)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (canRate && !order.isRatedByConsumer)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.star_border),
                      label: const Text('前往評價'),
                      onPressed: () {
                        Navigator.of(context)
                            .push<bool?>(
                          MaterialPageRoute(
                            builder: (ctx) => SubmitRatingPage(
                              orderId: order.id,
                            ),
                          ),
                        )
                            .then((result) {
                          if (result == true) {
                            context.read<OrderBloc>().add(OrdersFetched());
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber.shade800,
                        side: BorderSide(color: Colors.amber.shade700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}