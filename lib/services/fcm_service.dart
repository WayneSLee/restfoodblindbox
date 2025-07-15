import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:restfoodblindbox/bloc/store_orders/store_orders_bloc.dart';
import 'package:restfoodblindbox/main.dart';
import 'package:restfoodblindbox/models/app_notification_model.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/models/user_profile_model.dart';
import 'package:restfoodblindbox/pages/chat_page.dart';
import 'package:restfoodblindbox/pages/order_detail_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/services/notification_service.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/pages/store_detail_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("處理一個背景訊息: ${message.messageId}");
}

class FcmService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print("===== FCM Token: $fcmToken =====");
    if (fcmToken != null) {
      try {
        await ApiService.updateFcmToken(fcmToken);
      } catch (e) {
        print("更新 FCM Token 失敗: $e");
      }
    }
  }

  void initPushNotifications() {
    // 背景/終止狀態的通知點擊處理 (維持不變)
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 處理 App 在「前景」狀態時，收到通知的情況
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        print('收到前景訊息: ${notification.title}');

        // 3. 不再顯示 SnackBar，而是建立一個 AppNotification 物件
        final appNotification = AppNotification.fromRemoteMessage(message);

        // 4. 將這個通知物件，交給我們的 NotificationService 去處理
        NotificationService().addNotification(appNotification);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        print('收到前景訊息: ${notification.title}');

        // 2. 播放系統預設的通知音效
        FlutterRingtonePlayer().playNotification();

        // 3. 將通知交給 NotificationService 去處理（這部分不變）
        final appNotification = AppNotification.fromRemoteMessage(message);
        NotificationService().addNotification(appNotification);
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleNotificationClick(RemoteMessage message) async {
    print("使用者點擊了通知，Data: ${message.data}");

    final type = message.data['type'];
    final orderId = message.data['orderId']?.toString();
    final storeId = message.data['storeId']?.toString();

    if (orderId == null) return;

    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

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

        navigatorKey.currentState?.push(
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

        navigatorKey.currentState?.push(
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
      else if (type == 'new_product_from_favorite' && storeId != null) {
        // 如果是收藏店家上新通知，就直接跳到該店家頁面
        try {
          final Store store = await ApiService.fetchStoreById(storeId);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => StoreDetailPage(store: store),
            ),
          );
        } catch (e) {
          // 錯誤處理
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法開啟頁面: $e')),
      );
    }
  }
}