import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restfoodblindbox/pages/role_selection_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitRegister() async {
    // 透過 .validate() 觸發所有 TextFormField 的 validator
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. 使用 Email 和密碼建立使用者
        final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. 更新使用者的顯示名稱 (DisplayName)
        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(_nameController.text);
          // 重新載入使用者資料，確保後續操作能取到最新的資訊
          await userCredential.user!.reload();
        }

        // 3. 導航到身份選擇頁面
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('註冊成功，歡迎 ${_nameController.text}！')),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
                (route) => false,
          );
        }

      } on FirebaseAuthException catch (e) {
        // 4. 處理 Firebase 可能回傳的特定錯誤
        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = '密碼強度不足，請設定至少 6 位數的密碼。';
            break;
          case 'email-already-in-use':
            errorMessage = '這個 Email 已經被註冊過了。';
            break;
          case 'invalid-email':
            errorMessage = 'Email 格式不正確。';
            break;
          default:
            errorMessage = '發生未知錯誤，請稍後再試。';
        }
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if(mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email 格式驗證的輔助方法
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return '請輸入 Email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Email 格式錯誤';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊新帳號')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('建立您的帳號', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '您的稱呼/姓名', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? '請輸入您的稱呼' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密碼 (至少 6 位數)', border: OutlineInputBorder()),
                  validator: (value) => (value?.length ?? 0) < 6 ? '密碼至少需要 6 位數' : null,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('註冊'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('已經有帳號了？返回登入'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}