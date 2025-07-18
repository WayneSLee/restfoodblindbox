import 'package:flutter/material.dart';
import 'package:restfoodblindbox/pages/login_page.dart';

// 這是一個可以重複使用的函式，用來顯示登入提示
Future<void> showLoginPromptDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('請先登入'),
        content: const Text('您需要登入帳號才能使用此功能。'),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('前往登入'),
            onPressed: () {
              // 先關閉對話框，再跳轉到登入頁
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      );
    },
  );
}