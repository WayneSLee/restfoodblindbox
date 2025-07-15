import 'dart:convert';

// 將 JSON 字串轉換為 Store 列表的輔助函式
List<Store> storeFromJson(String str) => List<Store>.from(json.decode(str).map((x) => Store.fromJson(x)));

class Store {
  final String id;
  final String name;
  final String address;
  final String description;
  final double rating;
  final String imageUrl;
  final String googleMapsUrl;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String? openingTime;
  final String? closingTime;
  final List<int> daysOpen;
  final List<String> tags;
  final String? phone;
  final bool isFavorited; // 1. 新增 isFavorited 欄位

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.rating,
    required this.imageUrl,
    required this.googleMapsUrl,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.openingTime,
    this.closingTime,
    required this.daysOpen,
    required this.tags,
    this.phone,
    required this.isFavorited, // 2. 在建構子中加入
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    id: json["id"] ?? '',
    name: json["name"] ?? '名稱未知',
    address: json["address"] ?? '地址未知',
    description: json["description"] ?? '店家未提供描述',
    imageUrl: json["imageUrl"] ?? '',
    googleMapsUrl: json["googleMapsUrl"] ?? '',
    rating: (json["rating"] as num?)?.toDouble() ?? 0.0,
    latitude: (json["latitude"] as num?)?.toDouble() ?? 0.0,
    longitude: (json["longitude"] as num?)?.toDouble() ?? 0.0,
    distanceKm: (json["distanceKm"] as num?)?.toDouble() ?? 0.0,
    openingTime: json["openingTime"],
    closingTime: json["closingTime"],
    daysOpen: json["daysOpen"] != null
        ? List<int>.from(json["daysOpen"].map((x) => x as int))
        : [],
    tags: json["tags"] != null && json["tags"] is List
        ? List<String>.from(json["tags"].map((x) => x.toString()))
        : [],
    phone: json["phone"],
    isFavorited: json["isFavorited"] ?? false, // 3. 從 JSON 解析，預設為 false
  );

  bool get isOpen {
    if (openingTime == null || closingTime == null) {
      return false;
    }

    try {
      final now = DateTime.now();

      final openHour = int.parse(openingTime!.split(':')[0]);
      final openMinute = int.parse(openingTime!.split(':')[1]);
      final closeHour = int.parse(closingTime!.split(':')[0]);
      final closeMinute = int.parse(closingTime!.split(':')[1]);

      final openTime = DateTime(now.year, now.month, now.day, openHour, openMinute);
      var closeTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      // 判斷是否為跨日營業
      if (closeTime.isBefore(openTime)) {
        // 如果關店時間比開店時間早，代表是隔天關門，將關店日期加一天
        closeTime = closeTime.add(const Duration(days: 1));
      }

      // 重新判斷今天是否營業，並考慮跨日情況
      // 邏輯：
      // 1. 如果「現在」在「今天開店」和「今天關店」之間 -> 營業中
      // 2. 如果「現在」在「昨天開店」和「昨天關店(跨日)」之間 -> 營業中
      final yesterdayOpenTime = openTime.subtract(const Duration(days: 1));
      final yesterdayCloseTime = closeTime.subtract(const Duration(days: 1));

      bool isCurrentlyOpen = now.isAfter(openTime) && now.isBefore(closeTime);
      bool wasOpenYesterday = now.isAfter(yesterdayOpenTime) && now.isBefore(yesterdayCloseTime);

      if (isCurrentlyOpen || wasOpenYesterday) {
        // 在營業時間內，還需要檢查今天或昨天是否為營業日
        int checkDayOfWeek = closeTime.day > now.day ? now.subtract(const Duration(days: 1)).weekday : now.weekday;
        return daysOpen.contains(checkDayOfWeek);
      }

      return false;

    } catch (e) {
      print("Error parsing opening hours: $e");
      return false;
    }
  }
}