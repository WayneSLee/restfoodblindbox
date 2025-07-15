// 在 lib/models 資料夾下建立這個新檔案

class UserProfile {
  final String uid;
  final String email;
  final String role; // 我們預期後端會回傳 "consumer" 或 "store"
  final String? storeId; // 如果是店家，這個欄位才會有值

  UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.storeId,
  });

  /// 一個工廠建構子 (Factory Constructor)，用於從 JSON map 建立 UserProfile 物件
  /// 這能讓我們輕鬆地將 API 回傳的 JSON 資料轉換成 Dart 物件
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      email: json['email'],
      role: json['role'],
      storeId: json['storeId'], // 如果 JSON 中沒有這個 key，會自動設為 null
    );
  }
}
