import 'package:badges/badges.dart' as badges;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:restfoodblindbox/bloc/order/order_bloc.dart';
import 'package:restfoodblindbox/bloc/order/order_event.dart';
import 'package:restfoodblindbox/bloc/store/store_bloc.dart';
import 'package:restfoodblindbox/pages/my_orders_page.dart';
import 'package:restfoodblindbox/pages/notification_list_page.dart';
import 'package:restfoodblindbox/pages/profile_page.dart';
import 'package:restfoodblindbox/pages/store_list_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/services/fcm_service.dart';
import 'package:restfoodblindbox/services/notification_service.dart';
import 'package:restfoodblindbox/widgets/login_prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const _MainPageView(),
    );
  }
}

class _MainPageView extends StatefulWidget {
  const _MainPageView();

  @override
  State<_MainPageView> createState() => _MainPageViewState();
}

// 讓 State 類別混入 (with) WidgetsBindingObserver，使其能夠監聽 App 生命週期
class _MainPageViewState extends State<_MainPageView> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final GlobalKey _storeTabKey = GlobalKey();
  final GlobalKey _ordersTabKey = GlobalKey();
  final GlobalKey _notificationKey = GlobalKey();

  // 這是給「訪客」看的頁面列表
  static final List<Widget> _guestWidgetOptions = <Widget>[
    BlocProvider(
      create: (context) => StoreBloc(),
      child: const StoreListPage(),
    ),
    const Center(child: Text('請先登入以查看訂單')),
    const Center(child: Text('請先登入以查看個人資料')),
  ];

  // 這是給「已登入使用者」看的頁面列表
  static final List<Widget> _loggedInWidgetOptions = <Widget>[
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

    // 註冊生命週期監聽器
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGuide();
      // 首次進入 App 時，先更新一次位置
      _updateUserLocation();
    });
  }

  @override
  void dispose() {
    // 在頁面銷毀時，移除監聽器，避免記憶體洩漏
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 當 App 從背景恢復到前景時
    if (state == AppLifecycleState.resumed) {
      print("App has resumed. Updating user location.");
      // 再次觸發位置更新
      _updateUserLocation();
    }
  }


  /// 取得使用者目前位置並更新到後端
  Future<void> _updateUserLocation() async {
    // 只在已登入狀態下執行
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      final position = await _determinePosition();
      if (mounted) {
        // 呼叫我們在 ApiService 中建立的新方法
        await ApiService.updateUserLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      // 如果使用者拒絕權限，我們就靜默處理，不打擾使用者
      print("無法取得使用者位置來更新: $e");
    }
  }

  /// 決定使用者的目前位置 (此方法與 StoreBloc/MapBloc 中的完全相同)
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('定位服務已關閉。');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('定位權限已被拒絕。');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('定位權限已被永久拒絕，我們無法請求權限。');
    }

    return await Geolocator.getCurrentPosition();
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
    // 檢查點擊的是否為需要登入的分頁 (index 1 是訂單, index 2 是我的)
    if (index == 1 || index == 2) {
      // 檢查使用者是否已登入
      if (FirebaseAuth.instance.currentUser == null) {
        // 如果是訪客，顯示登入提示，並且不切換頁面
        showLoginPromptDialog(context);
        return; // 中斷後續的 setState
      }
    }
    // 如果是點擊「店家」(index 0) 或已登入使用者點擊其他分頁，才更新畫面
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 判斷當前是否登入
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

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
        // 根據登入狀態，選擇要使用的 Widget 列表
        child: isLoggedIn
            ? _loggedInWidgetOptions.elementAt(_selectedIndex)
            : _guestWidgetOptions.elementAt(_selectedIndex),
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
