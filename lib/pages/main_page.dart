import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:restfoodblindbox/bloc/order/order_bloc.dart';
import 'package:restfoodblindbox/bloc/order/order_event.dart';
import 'package:restfoodblindbox/bloc/store/store_bloc.dart';
import 'package:restfoodblindbox/pages/my_orders_page.dart';
import 'package:restfoodblindbox/pages/notification_list_page.dart';
import 'package:restfoodblindbox/pages/profile_page.dart';
import 'package:restfoodblindbox/pages/store_list_page.dart';
import 'package:restfoodblindbox/services/fcm_service.dart';
import 'package:restfoodblindbox/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- vvv 這是本次的修正 vvv ---
    // 修正 ShowCaseWidget 的 builder 寫法，移除多餘的 Builder()
    return ShowCaseWidget(
      builder: (context) => const _MainPageView(),
    );
    // --- ^^^ 修正到此結束 ^^^ ---
  }
}

// _MainPageView 是一個 StatefulWidget
class _MainPageView extends StatefulWidget {
  const _MainPageView();

  @override
  State<_MainPageView> createState() => _MainPageViewState();
}

// _MainPageViewState 是 _MainPageView 的狀態管理類
class _MainPageViewState extends State<_MainPageView> {
  int _selectedIndex = 0;

  final GlobalKey _storeTabKey = GlobalKey();
  final GlobalKey _ordersTabKey = GlobalKey();
  final GlobalKey _notificationKey = GlobalKey();

  static final List<Widget> _widgetOptions = <Widget>[
    BlocProvider(
      create: (context) => StoreBloc(),
      child: const StoreListPage(),
    ),
    BlocProvider(
      create: (context) => OrderBloc()..add(OrdersFetched()),
      child: const MyOrdersPage(),
    ),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    FcmService().initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowGuide());
  }

  void _checkAndShowGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenGuide = prefs.getBool('hasSeenGuide') ?? false;

    if (!hasSeenGuide && mounted) {
      ShowCaseWidget.of(context).startShowCase([
        _storeTabKey,
        _ordersTabKey,
        _notificationKey,
      ]);
      await prefs.setBool('hasSeenGuide', true);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['選擇店家', '我的訂單', '我的帳戶'][_selectedIndex]),
        actions: [
          Consumer<NotificationService>(
            builder: (context, service, child) {
              return Showcase(
                key: _notificationKey,
                description: '您可以在這裡查看所有通知訊息',
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  showBadge: service.unreadCount > 0,
                  badgeContent: Text(
                    service.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      service.markAllAsRead();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const NotificationListPage(),
                      ));
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Showcase(
              key: _storeTabKey,
              description: '點擊這裡，可以瀏覽附近的店家',
              child: const Icon(Icons.storefront_outlined),
            ),
            label: '店家',
          ),
          BottomNavigationBarItem(
            icon: Showcase(
              key: _ordersTabKey,
              description: '在這裡查看您的所有歷史訂單',
              child: const Icon(Icons.receipt_long),
            ),
            label: '訂單',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}