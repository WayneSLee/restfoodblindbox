import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_bloc.dart';
import 'package:restfoodblindbox/main.dart';
import 'package:restfoodblindbox/models/app_notification_model.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/models/user_profile_model.dart';
import 'package:restfoodblindbox/pages/chat_page.dart';
import 'package:restfoodblindbox/pages/order_detail_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/services/notification_service.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  // --- vvv 這是本次修改的核心 vvv ---
  // 將 FcmService 中的導航邏輯，完整地搬移並封裝成一個獨立的方法
  void _handleNotificationTap(
      BuildContext context, AppNotification notification) async {
    final type = notification.type;
    final orderId = notification.orderId;

    if (orderId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在載入頁面...')),
    );

    try {
      final UserProfile currentUserProfile = await ApiService.fetchUserProfile();
      final String userRole = currentUserProfile.role;

      if (type == 'chat_message') {
        final Order order = await ApiService.fetchOrderById(orderId);
        final String recipientName = userRole == 'store'
            ? order.customerProfile?.name ?? '顧客'
            : order.storeName;

        // 使用 context 來導航
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              orderId: orderId,
              recipientName: recipientName,
            ),
          ),
        );
      } else if (type == 'order_update' ||
          type == 'new_order' ||
          type == 'order_completed') {
        final Order order = await ApiService.fetchOrderById(orderId);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) {
              if (userRole == 'store') {
                return BlocProvider(
                  create: (context) => StoreOrdersBloc(),
                  child: OrderDetailPage(
                    order: order,
                    userRole: userRole,
                  ),
                );
              }
              return OrderDetailPage(
                order: order,
                userRole: userRole,
              );
            },
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法開啟頁面: $e')),
      );
    }
  }
  // --- ^^^ 修改到此結束 ^^^ ---

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
      ),
      body: notificationService.notifications.isEmpty
          ? const Center(
        child: Text('目前沒有任何通知。'),
      )
          : ListView.builder(
        itemCount: notificationService.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationService.notifications[index];
          return ListTile(
            leading: Icon(
              notification.isRead
                  ? Icons.notifications_none
                  : Icons.notifications_active,
              color: notification.isRead
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.bold),
            ),
            subtitle: Text(notification.body),
            trailing: Text(
              DateFormat('MM/dd HH:mm').format(notification.receivedAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              // 點擊後，呼叫我們剛剛建立的導航方法
              _handleNotificationTap(context, notification);
            },
          );
        },
      ),
    );
  }
}