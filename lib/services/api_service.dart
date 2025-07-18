import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:restfoodblindbox/env/env.dart'; // 1. 引入我們剛剛建立的 Env 類別
import 'package:restfoodblindbox/models/cart_model.dart';
import 'package:restfoodblindbox/models/order_model.dart';
import 'package:restfoodblindbox/models/product_model.dart';
import 'package:restfoodblindbox/models/store_model.dart';
import 'package:restfoodblindbox/models/user_profile_model.dart';
import 'package:restfoodblindbox/models/rating_model.dart';
import 'package:restfoodblindbox/services/api_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:restfoodblindbox/models/sales_report_model.dart';

class ApiService {
  // 2. 將寫死的 _baseUrl，改為從 Env 類別讀取
  static const String _baseUrl = Env.apiUrl;

  // --- 所有其他的方法都維持不變，它們會自動使用新的 _baseUrl ---

  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  static Future<UserProfile> fetchUserProfile() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw UserNotFoundInApiException('在後端資料庫中找不到使用者');
    } else {
      throw Exception('無法載入使用者資料: 狀態碼 ${response.statusCode}');
    }
  }

  static Future<void> createUserProfile({required String role}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('使用者未登入');

    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await user.getIdToken()}',
      },
      body: jsonEncode({'role': role}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('建立使用者資料失敗: ${response.body}');
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Firestore user document created for uid: ${user.uid}');
    } catch (e) {
      print('Failed to create Firestore user document: $e');
    }
  }

  static Future<List<Store>> fetchStores(
      {required double userLat, required double userLon}) async {
    final token = await _getAuthToken();
    final queryParameters = {
      'userLat': userLat.toString(),
      'userLon': userLon.toString(),
      'radiusKm': '10',
    };

    // 由於 baseUrl 現在可能包含 Port，我們需要改用 Uri.parse 來組合
    final uri = Uri.parse("$_baseUrl/stores").replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return storeFromJson(response.body);
    } else {
      throw Exception('Failed to load stores from API. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  static Future<List<Product>> fetchProductsByStore(String storeId) async {
    final response =
    await http.get(Uri.parse('$_baseUrl/stores/$storeId/products'));
    if (response.statusCode == 200) {
      return productFromJson(response.body);
    } else {
      throw Exception('Failed to load products for store $storeId');
    }
  }

  static Future<String> createStore(Map<String, dynamic> storeData) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入，無法建立店家');

    final response = await http.post(
      Uri.parse('$_baseUrl/stores'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(storeData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final String? newStoreId = responseBody['storeId'] ?? responseBody['id'];
      if (newStoreId != null) {
        return newStoreId;
      } else {
        throw Exception('建立店家成功，但回應中找不到店家 ID。');
      }
    } else {
      throw Exception('建立店家失敗: ${response.body}');
    }
  }

  static Future<void> createProduct(
      String storeId, Map<String, dynamic> productData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/stores/$storeId/products'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );
    if (response.statusCode != 201) {
      throw Exception('新增商品失敗: ${response.body}');
    }
  }

  static Future<void> updateProduct(
      int productId, Map<String, dynamic> productData) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('更新商品失敗: ${response.body}');
    }
  }

  static Future<void> deleteProduct(int productId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('刪除商品失敗: ${response.body}');
    }
  }

  static Future<void> createOrder(
      String storeId, List<CartItem> cartItems) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final List<Map<String, dynamic>> itemsPayload = cartItems.map((item) {
      return {'productId': item.productId, 'quantity': item.quantity};
    }).toList();

    final orderPayload = {'storeId': storeId, 'items': itemsPayload};

    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(orderPayload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('建立訂單失敗: ${response.body}');
    }
  }

  static Future<List<Order>> fetchMyOrders() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.get(
      Uri.parse('$_baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('無法載入訂單列表: ${response.body}');
    }
  }

  static Future<List<Order>> fetchStoreOrders(String storeId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.get(
      Uri.parse('$_baseUrl/stores/$storeId/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('無法載入店家訂單列表: ${response.body}');
    }
  }

  static Future<void> acceptOrder(String orderId) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('接受訂單失敗: ${response.body}');
    }
  }

  static Future<void> rejectOrder(String orderId) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId/reject'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('拒絕訂單失敗: ${response.body}');
    }
  }

  static Future<void> updateFcmToken(String fcmToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': fcmToken},
        SetOptions(merge: true),
      );
    } catch (e) {
      print("儲存 FCM Token 到 Firestore 時發生錯誤: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/me/fcm-token'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        print('更新 FCM Token 到您的後端 API 失敗: ${response.body}');
      }
    } catch (e) {
      print("呼叫後端 API 更新 FCM Token 時發生錯誤: $e");
    }
  }

  static Future<void> completeOrder(String orderId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/complete'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('訂單核銷失敗: ${response.body}');
    }
  }

  static Future<void> submitRating({
    required String orderId,
    required int score,
    String? comment,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final body = jsonEncode({
      'score': score,
      'comment': comment,
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/ratings'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('提交評價失敗: ${response.body}');
    }
  }

  static Future<List<Rating>> fetchStoreRatings(String storeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stores/$storeId/ratings'),
    );

    if (response.statusCode == 200) {
      return ratingFromJson(response.body);
    } else {
      throw Exception('無法載入店家評價: ${response.body}');
    }
  }

  static Future<Order> fetchOrderById(String orderId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('無法載入訂單詳情: ${response.body}');
    }
  }

  static Future<void> updateStoreInfo(
      String storeId, Map<String, dynamic> storeData) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入，無法更新店家資訊');

    final response = await http.put(
      Uri.parse('$_baseUrl/stores/$storeId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(storeData),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('更新店家資訊失敗: ${response.body}');
    }
  }

  static Future<Store> fetchStoreById(String storeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stores/$storeId'),
    );

    if (response.statusCode == 200) {
      return Store.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('無法載入店家資料: ${response.body}');
    }
  }

  static Future<SalesReport> fetchSalesReport(String storeId,
      {String period = 'weekly'}) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final uri =
    Uri.parse('$_baseUrl/stores/$storeId/sales-report?period=$period');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return salesReportFromJson(response.body);
    } else {
      throw Exception('無法載入銷售報告: ${response.body}');
    }
  }

  static Future<void> addFavoriteStore(String storeId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.post(
      Uri.parse('$_baseUrl/favorites/stores'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'storeId': storeId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('新增收藏失敗: ${response.body}');
    }
  }

  static Future<void> removeFavoriteStore(String storeId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.delete(
      Uri.parse('$_baseUrl/favorites/stores/$storeId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('移除收藏失敗: ${response.body}');
    }
  }

  static Future<List<Store>> fetchFavoriteStores() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.get(
      Uri.parse('$_baseUrl/favorites/stores'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return storeFromJson(response.body);
    } else {
      throw Exception('無法載入收藏店家列表: ${response.body}');
    }
  }

  /// 呼叫後端 API 來刪除使用者帳號及其所有資料
  static Future<void> deleteAccount() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('使用者未登入');

    final response = await http.delete(
      Uri.parse('$_baseUrl/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // 後端成功處理刪除後，通常會回傳 200 OK 或 204 No Content
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('刪除帳號失敗: ${response.body}');
    }
  }

  static Future<String> signInWithApple({
    required String identityToken,
    String? fullName,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/apple'), // 這是我們在後端規格中定義的端點
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'identityToken': identityToken,
        'fullName': fullName,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      // 預期後端會回傳一個 JSON，裡面包含 Firebase Custom Token
      final responseBody = jsonDecode(response.body);
      final String? customToken = responseBody['customToken'];
      if (customToken != null) {
        return customToken;
      } else {
        throw Exception("後端回應中找不到 Custom Token");
      }
    } else {
      throw Exception('Apple 登入後端驗證失敗: ${response.body}');
    }
  }
}