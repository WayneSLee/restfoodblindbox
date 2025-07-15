// lib/services/image_upload_service.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  // 這是對外提供的主要方法
  Future<String?> pickAndUploadImage(BuildContext context) async {
    // 1. 讓使用者選擇來源
    final source = await _showImageSourceDialog(context);
    if (source == null) return null; // 使用者取消選擇

    // 2. 根據選擇的來源，從相機或相簿中取得圖片
    final XFile? imageFile = await _picker.pickImage(source: source);
    if (imageFile == null) return null; // 使用者沒有選擇任何圖片

    // 3. 壓縮圖片
    final Uint8List compressedImageData = await _compressImage(imageFile);

    // 4. 上傳到後端
    try {
      final String imageUrl = await _uploadImage(compressedImageData);
      return imageUrl;
    } catch (e) {
      // 如果發生錯誤，顯示一個提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('圖片上傳失敗: $e')),
        );
      }
      return null;
    }
  }

  // 內部方法：顯示選擇對話框
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇圖片來源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('從相簿選擇'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('使用相機拍攝'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  // 內部方法：壓縮圖片
  Future<Uint8List> _compressImage(XFile file) async {
    final Uint8List imageData = await file.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageData);

    if (originalImage == null) {
      throw Exception('無法解碼圖片');
    }

    // 調整圖片尺寸，設定寬度最大為 800 像素，高度會等比例縮放
    final img.Image resizedImage = img.copyResize(originalImage, width: 800);

    // 將處理過的圖片重新編碼為 JPEG 格式，並設定壓縮品質 (85)
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  // 內部方法：上傳圖片到後端
  Future<String> _uploadImage(Uint8List imageData) async {
    // 取得 Firebase 使用者的認證 token
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('使用者未登入，無法上傳圖片');
    }

    // 您的後端 API 端點
    final uri = Uri.parse('https://www.kuanxingtech.com.tw:5765/api/upload/image');

    // 建立一個 "multipart" 請求
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageData,
        filename: 'upload.jpg',
      ));

    // 發送請求
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decodedJson = jsonDecode(responseBody);

      // *** 主要修改點：將 'imageUrl' 改為 'url' ***
      final imageUrl = decodedJson['url'];

      if (imageUrl != null) {
        return imageUrl;
      } else {
        // 現在我們預期 key 是 'url'
        throw Exception("API 回應中找不到 'url' 欄位");
      }
    } else {
      throw Exception('圖片上傳失敗，狀態碼: ${response.statusCode}');
    }
  }
}