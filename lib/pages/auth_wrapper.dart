import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/user_profile_model.dart';
import 'package:restfoodblindbox/pages/login_page.dart';
import 'package:restfoodblindbox/pages/main_page.dart';
import 'package:restfoodblindbox/pages/role_selection_page.dart'; // 1. 引入身份選擇頁
import 'package:restfoodblindbox/pages/store_dashboard_page.dart';
import 'package:restfoodblindbox/services/api_exceptions.dart'; // 2. 引入 Exception 檔案
import 'package:restfoodblindbox/services/api_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          return FutureBuilder<UserProfile>(
            future: ApiService.fetchUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (profileSnapshot.hasError) {
                final error = profileSnapshot.error;
                // 3. 檢查錯誤的類型
                if (error is UserNotFoundInApiException) {
                  // 如果是找不到使用者，代表是新用戶，導向到身份選擇頁
                  return const RoleSelectionPage();
                } else {
                  // 如果是其他錯誤，才顯示錯誤畫面
                  return Scaffold(
                    body: Center(child: Text('無法載入使用者資訊: $error')),
                  );
                }
              }

              if (profileSnapshot.hasData) {
                // ... (根據角色導航的邏輯不變) ...
                final userProfile = profileSnapshot.data!;

                if (userProfile.role == 'store' && userProfile.storeId != null) {
                  return StoreDashboardPage(storeId: userProfile.storeId!);
                } else {
                  return const MainPage();
                }
              }

              return const LoginPage();
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
