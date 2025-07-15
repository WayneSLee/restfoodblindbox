// lib/models/app_notification_model.dart

import 'package:firebase_messaging/firebase_messaging.dart';

class AppNotification {
  final String title;
  final String body;
  final String? type; // 'chat_message', 'order_update', etc.
  final String? orderId;
  final DateTime receivedAt;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    this.type,
    this.orderId,
    required this.receivedAt,
    this.isRead = false,
  });

  // 一個方便的工廠方法，可以直接從 Firebase 的 RemoteMessage 建立我們的通知物件
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      title: message.notification?.title ?? '新通知',
      body: message.notification?.body ?? '您有一則新通知',
      type: message.data['type'],
      orderId: message.data['orderId']?.toString(),
      receivedAt: DateTime.now(),
    );
  }
}