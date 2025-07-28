import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:restfoodblindbox/bloc/cart/cart_bloc.dart';
import 'package:restfoodblindbox/firebase_options.dart';
import 'package:restfoodblindbox/pages/auth_wrapper.dart';
import 'package:restfoodblindbox/pages/cart.dart';
import 'package:restfoodblindbox/services/fcm_service.dart';
import 'package:restfoodblindbox/services/notification_service.dart';
import 'package:restfoodblindbox/services/theme_notifier.dart'; // 1. 引入 ThemeNotifier
import 'package:restfoodblindbox/widgets/floating_cart_button.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<String> currentRouteName = ValueNotifier('');

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRouteName.value = route.settings.name ?? '';
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRouteName.value = previousRoute?.settings.name ?? '';
    super.didPop(route, previousRoute);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FcmService().initPushNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- vvv 定義淺色主題 vvv ---
    final lightTheme = ThemeData(
      primarySwatch: Colors.green, // 這裡我們先用一個接近的 MaterialColor
      primaryColor: const Color(0xFFA7D7C5), // 主色：淡抹茶綠
      scaffoldBackgroundColor: const Color(0xFFF9F6F2), // 背景：燕麥奶米白
      brightness: Brightness.light,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFA7D7C5), // 導覽列背景：淡抹茶綠
        foregroundColor: Color(0xFF2E2E2E), // 導覽列文字：深灰
        elevation: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7F6A93), // 按鈕背景：低彩度紫色
          foregroundColor: Colors.white, // 按鈕文字：白色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF6C77D).withOpacity(0.2), // 分類標籤：奶油金黃(半透明)
        labelStyle: const TextStyle(color: Color(0xFF2E2E2E)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Color(0xFFF6C77D),
            )),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFA7D7C5), // 點擊後的圖示顏色：淡抹茶綠
        unselectedItemColor: Colors.grey[500],
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: Color(0xFF2E2E2E)), // 標題文字：深灰
        bodyLarge: TextStyle(color: Color(0xFF2E2E2E)),     // 內文文字：深灰
        bodyMedium: TextStyle(color: Color(0xFFA0A0A0)),    // 次要文字：淺灰
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    // --- ^^^ 淺色主題定義結束 ^^^ ---

    // --- vvv 定義深色主題 vvv ---
    final darkTheme = ThemeData(
      primarySwatch: Colors.orange,
      brightness: Brightness.dark, // 指明這是深色主題
      scaffoldBackgroundColor: const Color(0xFF121212), // 深灰色背景
      cardColor: const Color(0xFF1E1E1E), // 卡片使用稍微亮一點的深灰
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900], // AppBar 使用更深的灰色
        foregroundColor: Colors.orange[400],
        elevation: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.orange[700],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: Colors.grey[800],
    );
    // --- ^^^ 深色主題定義結束 ^^^ ---

    return MultiProvider(
      providers: [
        BlocProvider(create: (_) => CartBloc()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()), // 2. 加入 ThemeNotifier
      ],
      child: Consumer<ThemeNotifier>( // 3. 使用 Consumer 來監聽 ThemeNotifier
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: '剩食盲盒',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeNotifier.themeMode, // 4. 讓主題模式由 Notifier 控制
            builder: (context, child) {
              return Stack(
                children: [
                  if (child != null) child,
                  const Positioned(
                    right: 0,
                    bottom: 80,
                    child: FloatingCartButton(),
                  ),
                ],
              );
            },
            navigatorObservers: [AppRouteObserver()],
            routes: {
              '/': (context) => const AuthWrapper(),
              '/cart': (context) => const CartPage(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}