// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/app_notification_model.dart';

// 使用 ChangeNotifier，這樣 UI 就可以監聽它的變化並自動更新
class NotificationService extends ChangeNotifier {
  // --- 單例模式的實作 ---
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();
  // --------------------

  final List<AppNotification> _notifications = [];

  // 提供一個外部可以讀取的通知列表
  List<AppNotification> get notifications => _notifications;

  // 計算未讀通知的數量
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // 新增一則通知
  void addNotification(AppNotification notification) {
    // 將新通知加在列表的最前面
    _notifications.insert(0, notification);
    // 通知所有正在監聽這個服務的 UI 元件，告訴它們：「嘿，資料變了，該更新畫面囉！」
    notifyListeners();
  }

  // 將所有通知標示為已讀
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }
}