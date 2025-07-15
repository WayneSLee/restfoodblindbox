import 'package:firebase_auth/firebase_auth.dart'; // 1. 引入 Firebase Auth
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 2. 引入 Google Sign In
import 'package:restfoodblindbox/bloc/my_products/my_products_bloc.dart';
import 'package:restfoodblindbox/pages/create_ticket_page.dart';
import 'package:restfoodblindbox/pages/edit_store_info_page.dart';
import 'package:restfoodblindbox/pages/login_page.dart'; // 3. 引入登入頁
import 'package:restfoodblindbox/pages/my_products_page.dart';
import 'package:restfoodblindbox/pages/my_support_tickets_page.dart';
import 'package:restfoodblindbox/pages/qr_scanner_page.dart';
import 'package:restfoodblindbox/pages/sales_report_page.dart';
import 'package:restfoodblindbox/pages/store_orders_page.dart';
import 'package:restfoodblindbox/services/fcm_service.dart';

class StoreDashboardPage extends StatefulWidget {
  final String storeId;
  const StoreDashboardPage({super.key, required this.storeId});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  @override
  void initState() {
    super.initState();
    FcmService().initNotifications();
  }

  // --- vvv 這是新增的登出方法 vvv ---
  Future<void> _signOut(BuildContext context) async {
    // 顯示確認對話框
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認登出'),
          content: const Text('您確定要登出您的店家帳號嗎？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('確定登出', style: TextStyle(color: Colors.red.shade700)),
            ),
          ],
        );
      },
    );

    // 如果使用者確認登出，才執行登出邏輯
    if (confirmLogout == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      // 登出後導航回登入頁面，並清除所有舊頁面
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }
  // --- ^^^ 新增方法到此結束 ^^^ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店家管理中心'),
        automaticallyImplyLeading: false,
        // --- vvv 這是新增的 actions 屬性 vvv ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context), // 呼叫登出方法
            tooltip: '登出',
          ),
        ],
        // --- ^^^ 新增到此結束 ^^^ ---
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: <Widget>[
          _buildDashboardCard(
            context,
            icon: Icons.fastfood,
            label: '我的商品',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (context) => MyProductsBloc(),
                    child: MyProductsPage(storeId: widget.storeId),
                  ),
                ),
              );
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.receipt_long,
            label: '訂單管理',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StoreOrdersPage(storeId: widget.storeId),
                ),
              );
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.qr_code_scanner,
            label: '掃描核銷',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerPage()),
              );
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.bar_chart,
            label: '銷售報告',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SalesReportPage(storeId: widget.storeId),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.store,
            label: '店家資訊',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditStoreInfoPage(storeId: widget.storeId),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.support_agent,
            label: '聯絡客服',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CreateTicketPage(),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.history_edu,
            label: '我的客服案件',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MySupportTicketsPage(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    // ... 這個方法維持不變 ...
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}