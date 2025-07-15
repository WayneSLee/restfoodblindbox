/// 用於表示在後端資料庫中找不到使用者紀錄的特定錯誤。
class UserNotFoundInApiException implements Exception {
  final String message;
  UserNotFoundInApiException(this.message);

  @override
  String toString() => message;
}
