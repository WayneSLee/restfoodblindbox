// lib/pages/store_registration_page.dart

import 'package:flutter/material.dart';
import 'package:restfoodblindbox/pages/store_dashboard_page.dart';
import 'package:restfoodblindbox/services/api_service.dart';
import 'package:restfoodblindbox/services/image_upload_service.dart'; // 1. 引入新服務

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 2. 用於儲存上傳成功後的圖片 URL
  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 3. 處理圖片上傳的邏輯
  Future<void> _handleImageUpload() async {
    setState(() => _isUploading = true);
    final service = ImageUploadService();
    final imageUrl = await service.pickAndUploadImage(context);

    if (imageUrl != null) {
      setState(() {
        _imageUrl = imageUrl;
      });
    }
    setState(() => _isUploading = false);
  }

  Future<void> _submitForm() async {
    // 驗證表單
    if (_formKey.currentState!.validate()) {
      // 4. 驗證使用者是否已上傳圖片
      if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先上傳一張店家照片')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // 5. 使用 _imageUrl 來建立資料
      final storeData = {
        "name": _nameController.text,
        "address": _addressController.text,
        "category": _categoryController.text,
        "description": _descriptionController.text,
        "imageUrl": _imageUrl, // 使用上傳後的 URL
        // googleMapsUrl 和 rating 由後端處理或給預設值，前端不用傳
      };

      try {
        final newStoreId = await ApiService.createStore(storeData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('店家資料已提交！歡迎加入！')),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => StoreDashboardPage(storeId: newStoreId),
            ),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('提交失敗: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('申請成為店家'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... 其他 TextFormField 維持不變 ...
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '店家名稱'),
                validator: (value) => value!.isEmpty ? '請輸入店家名稱' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: '店家地址'),
                validator: (value) => value!.isEmpty ? '請輸入店家地址' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: '店家類別 (例如: 台灣小吃, 手搖飲)'),
                validator: (value) => value!.isEmpty ? '請輸入店家類別' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '店家描述'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? '請輸入店家描述' : null,
              ),
              const SizedBox(height: 24),

              // --- vvv 這裡是新的圖片上傳 UI vvv ---
              const Text('店家照片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _imageUrl == null
                      ? const Text('尚未上傳照片', style: TextStyle(color: Colors.grey))
                      : Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 8),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                onPressed: _handleImageUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('選擇並上傳照片'),
              ),
              // --- ^^^ 這裡是新的圖片上傳 UI ^^^ ---

              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('提交申請'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}