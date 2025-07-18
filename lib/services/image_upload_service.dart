import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restfoodblindbox/env/env.dart'; // 1. 引入我們建立的 Env 類別

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadImage(BuildContext context) async {
    final source = await _showImageSourceDialog(context);
    if (source == null) return null;

    final XFile? imageFile = await _picker.pickImage(source: source);
    if (imageFile == null) return null;

    final Uint8List compressedImageData = await _compressImage(imageFile);

    try {
      final String imageUrl = await _uploadImage(compressedImageData);
      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('圖片上傳失敗: $e')),
        );
      }
      return null;
    }
  }

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

  Future<Uint8List> _compressImage(XFile file) async {
    final Uint8List imageData = await file.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageData);

    if (originalImage == null) {
      throw Exception('無法解碼圖片');
    }

    final img.Image resizedImage = img.copyResize(originalImage, width: 800);
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  Future<String> _uploadImage(Uint8List imageData) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('使用者未登入，無法上傳圖片');
    }

    // --- vvv 這是本次修改的核心 vvv ---
    // 將寫死的網址，改為從 Env.apiUrl 動態組合
    final uri = Uri.parse('${Env.apiUrl}/upload/image');
    // --- ^^^ 修改到此結束 ^^^ ---

    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageData,
        filename: 'upload.jpg',
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decodedJson = jsonDecode(responseBody);
      final imageUrl = decodedJson['url'];

      if (imageUrl != null) {
        return imageUrl;
      } else {
        throw Exception("API 回應中找不到 'url' 欄位");
      }
    } else {
      throw Exception('圖片上傳失敗，狀態碼: ${response.statusCode}');
    }
  }
}