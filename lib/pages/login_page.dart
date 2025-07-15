import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// 我們不再需要手動導航到 MainPage，所以可以移除這個引用
// import 'package:restfoodblindbox/pages/main_page.dart';
import 'package:restfoodblindbox/pages/register_page.dart';
import 'package:restfoodblindbox/pages/role_selection_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 傳統 Email/密碼登入
  Future<void> _submitLogin() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // --- vvv 這是本次修改的核心 vvv ---
      // 登入成功後，我們不再手動導航。
      // AuthWrapper 會自動監聽到 Auth 狀態變化並處理後續導航。
      // if (mounted) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const MainPage()),
      //   );
      // }
      // --- ^^^ 修改到此結束 ^^^ ---
    } on FirebaseAuthException catch (e) {
      // 登入失敗時，顯示錯誤訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? '登入失敗')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Google 登入邏輯
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // 使用者取消了 Google 登入
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // --- vvv 這是本次修改的核心 vvv ---
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // 對於新用戶，我們仍然需要導向到身份選擇頁，因為 AuthWrapper 無法判斷新用戶該去哪
      if (isNewUser && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
              (route) => false,
        );
      }
      // 對於舊用戶，我們同樣不再手動導航，交給 AuthWrapper 處理
      // else if (mounted) {
      //   Navigator.of(context).pushAndRemoveUntil(
      //     MaterialPageRoute(builder: (context) => const MainPage()),
      //     (route) => false,
      //   );
      // }
      // --- ^^^ 修改到此結束 ^^^ ---

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 登入失敗: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... UI 部分維持不變 ...
    return Scaffold(
      appBar: AppBar(title: const Text('登入')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('歡迎回來',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '密碼', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _submitLogin,
                      child: const Text('登入'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Image.asset('assets/google_logo.png', height: 24.0),
                      label: const Text('使用 Google 登入'),
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text('還沒有帳號？點我註冊'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}