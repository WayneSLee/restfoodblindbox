import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:restfoodblindbox/pages/create_ticket_page.dart';
import 'package:restfoodblindbox/pages/favorite_stores_page.dart'; // 1. 引入我們稍後會建立的新頁面
import 'package:restfoodblindbox/pages/login_page.dart';
import 'package:restfoodblindbox/pages/my_support_tickets_page.dart';
import 'package:restfoodblindbox/services/theme_notifier.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/pages/about_us_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// 處理刪除帳號的完整流程
  Future<void> _handleDeleteAccount(BuildContext context) async {
    // 步驟 1: 顯示第一層警告對話框
    final bool? confirmFirst = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 確認刪除帳號'),
        content: const Text(
            '這是一個無法復原的操作！您所有的個人資料、訂單紀錄、收藏店家都將被永久刪除。您確定要繼續嗎？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text('我確定要刪除', style: TextStyle(color: Colors.red.shade700)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    // 如果使用者取消，則中止流程
    if (confirmFirst != true) return;

    // 步驟 2: 再次確認 (可以要求使用者輸入 "DELETE" 來確認)
    final confirmController = TextEditingController();
    final bool? confirmSecond = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('請再次確認'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('為確保安全，請在下方輸入「DELETE」以確認刪除。'),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: Text('確認刪除', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () {
                if (confirmController.text == 'DELETE') {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
          ],
        ));

    // 如果第二次確認失敗，也中止流程
    if (confirmSecond != true) return;

    // 步驟 3: 執行刪除
    try {
      // 顯示處理中的指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在處理刪除請求...')),
      );

      // 呼叫 API
      await ApiService.deleteAccount();

      // 刪除成功後，登出並跳轉回登入頁
      if (context.mounted) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    Future<void> signOut() async {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (context.mounted) {
        // --- vvv 這是本次修改的核心 vvv ---
        // 將直接導向 LoginPage，改為導向到根路由 '/'
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
              (Route<dynamic> route) => false,
        );
        // --- ^^^ 修改到此結束 ^^^ ---
      }
    }

    void showThemeDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return AlertDialog(
                title: const Text('選擇外觀模式'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('淺色模式'),
                      value: ThemeMode.light,
                      groupValue: themeNotifier.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('深色模式'),
                      value: ThemeMode.dark,
                      groupValue: themeNotifier.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('跟隨系統'),
                      value: ThemeMode.system,
                      groupValue: themeNotifier.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              if (user?.photoURL != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user!.photoURL!),
                )
              else
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? '使用者',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '未提供 Email',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const Divider(height: 48),

        // --- vvv 這是本次新增的 UI vvv ---
        ListTile(
          leading: const Icon(Icons.favorite_border),
          title: const Text('我的收藏'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // 點擊後導航到新的收藏頁面
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const FavoriteStoresPage(),
            ));
          },
        ),
        // --- ^^^ 新增到此結束 ^^^ ---

        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('外觀模式'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: showThemeDialog,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('關於我們'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AboutUsPage(),
            ));
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text('聯絡客服'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CreateTicketPage(),
            ));
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('我的客服案件'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const MySupportTicketsPage(),
            ));
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.no_accounts, color: Colors.red.shade700),
          title: Text('刪除帳號', style: TextStyle(color: Colors.red.shade700)),
          onTap: () => _handleDeleteAccount(context),
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red.shade700),
          title: Text('登出', style: TextStyle(color: Colors.red.shade700)),
          onTap: signOut,
        ),
      ],
    );
  }
}