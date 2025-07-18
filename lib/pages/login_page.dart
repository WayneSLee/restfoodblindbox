import 'dart:io'; // 引入 dart:io 來判斷平台
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:restfoodblindbox/pages/register_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 引入新套件

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

  Future<void> _handleSuccessfulLogin() async {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop(true);
    }
    // 如果不能 pop，AuthWrapper 會處理後續跳轉
  }

  Future<void> _submitLogin() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _handleSuccessfulLogin();
    } on FirebaseAuthException catch (e) {
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
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

      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      // 如果是新註冊的使用者，需要先去後端建立資料
      // 注意：Google 登入預設為 consumer 身份
      if (isNewUser) {
        await ApiService.createUserProfile(role: 'consumer');
      }

      await _handleSuccessfulLogin();
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

  // --- vvv 這是新增的 Apple 登入方法 vvv ---
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      // 1. 向 Apple 請求使用者授權
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 2. 將從 Apple 取得的資訊，傳送到您的後端 API
      //    後端會負責驗證並建立/登入使用者，然後回傳 Firebase Custom Token 和 isNewUser 狀態
      final Map<String, dynamic> authData = await ApiService.signInWithApple(
          identityToken: credential.identityToken!,
          fullName: (credential.givenName ?? '') + (credential.familyName ?? ''),
          email: credential.email
      );

      final String customToken = authData['customToken'];
      final bool isNewUser = authData['isNewUser'];

      // 3. 使用後端回傳的 Custom Token 登入 Firebase
      await _auth.signInWithCustomToken(customToken);

      // 4. 如果是新使用者，在後端為他們建立一個預設的 consumer 身份
      if (isNewUser) {
        await ApiService.createUserProfile(role: 'consumer');
      }

      // 5. 執行前端的成功登入流程
      await _handleSuccessfulLogin();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple 登入失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- ^^^ 新增到此結束 ^^^ ---

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                keyboardType: TextInputType.emailAddress,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _submitLogin,
                      child: const Text('登入'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Image.asset('assets/google_logo.png', height: 24.0),
                      label: const Text('使用 Google 登入'),
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    // --- vvv 這是新增的 Apple 登入按鈕 vvv ---
                    // 只在 iOS 平台上顯示 Apple 登入按鈕
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      SignInWithAppleButton(
                        onPressed: _signInWithApple,
                        style: SignInWithAppleButtonStyle.black, // 可選 black, white, whiteOutlined
                      ),
                    ],
                    // --- ^^^ 新增到此結束 ^^^ ---
                  ],
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
        ),
      ),
    );
  }
}