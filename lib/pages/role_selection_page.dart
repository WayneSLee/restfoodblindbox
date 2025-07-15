import 'package:flutter/material.dart';
import 'package:restfoodblindbox/pages/main_page.dart';
import 'package:restfoodblindbox/pages/store_registration_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 呼叫 API 在後端建立使用者資料
      await ApiService.createUserProfile(role: role);

      if (mounted) {
        if (role == 'store') {
          // 如果是店家，導向到店家註冊表單
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const StoreRegistrationPage()),
          );
        } else {
          // 如果是消費者，導向到主頁面
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainPage()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定身份失敗: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
    // 注意：成功導航後不需要再設定 isLoading 為 false，因為頁面已經被替換
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇您的身份'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Icon 和 Text 不變) ...
              const Icon(Icons.person_search, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                '歡迎加入！\n請選擇您的身份：',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // 消費者按鈕
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag),
                label: const Text('我是一般使用者'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () => _selectRole('consumer'),
              ),
              const SizedBox(height: 20),

              // 店家按鈕
              OutlinedButton.icon(
                icon: const Icon(Icons.storefront),
                label: const Text('我要成為店家'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () => _selectRole('store'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
