import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/user_profile_model.dart';
import 'package:restfoodblindbox/pages/login_page.dart';
import 'package:restfoodblindbox/pages/main_page.dart';
import 'package:restfoodblindbox/pages/role_selection_page.dart';
import 'package:restfoodblindbox/pages/store_dashboard_page.dart';
import 'package:restfoodblindbox/services/api_exceptions.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/widgets/custom_loading_indicator.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 狀態一：正在驗證使用者登入狀態
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: CustomLoadingIndicator());
        }

        // --- vvv 這是本次修改的核心 vvv ---
        // 狀態二：使用者已登入
        if (authSnapshot.hasData) {
          // 如果已登入，就和以前一樣，去後端獲取使用者角色資料
          return FutureBuilder<UserProfile>(
            future: ApiService.fetchUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: CustomLoadingIndicator());
              }

              if (profileSnapshot.hasError) {
                final error = profileSnapshot.error;
                if (error is UserNotFoundInApiException) {
                  // 新註冊的使用者，導向到身份選擇頁
                  return const RoleSelectionPage();
                } else {
                  // 其他錯誤，顯示錯誤畫面
                  return Scaffold(
                    body: Center(child: Text('無法載入使用者資訊: $error')),
                  );
                }
              }

              if (profileSnapshot.hasData) {
                // 根據角色，導向到店家後台或消費者主頁
                final userProfile = profileSnapshot.data!;
                if (userProfile.role == 'store' && userProfile.storeId != null) {
                  return StoreDashboardPage(storeId: userProfile.storeId!);
                } else {
                  return const MainPage();
                }
              }

              // 預防萬一，如果 FutureBuilder 沒資料但 Auth 有，先顯示載入中
              return const Scaffold(body: CustomLoadingIndicator());
            },
          );
        } else {
          // 狀態三：使用者未登入 (訪客模式)
          // 直接讓使用者進入主頁面！
          return const MainPage();
        }
        // --- ^^^ 修改到此結束 ^^^ ---
      },
    );
  }
}