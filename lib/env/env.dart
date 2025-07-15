// 這是一個用來讀取原生平台（Android/iOS）定義的環境變數的類別。

class Env {
  // 我們定義一個靜態的、不可變的變數來存放 API 的 URL。
  // 我們使用 `fromEnvironment` 這個構造函數，來讀取在編譯時期傳入的環境變數。
  // 'API_URL' 這個名稱，必須與我們在 build.gradle.kts 中定義的 buildConfigField 名稱完全一致。
  // 如果在編譯時沒有找到這個變數，它會使用一個預設的空字串 ''。
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');

  // 我們也可以定義一個布林值，來判斷當前是否為開發模式。
  // 這可以透過 Dart 編譯器在執行 `flutter run` 時自動定義的 'dart.library.io' 來判斷。
  static const bool isDevelopment = bool.fromEnvironment('dart.vm.product') == false;
}