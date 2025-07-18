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
      primarySwatch: Colors.orange,
      brightness: Brightness.light, // 指明這是淺色主題
      scaffoldBackgroundColor: const Color(0xFFF8F5F2),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.orange,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
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