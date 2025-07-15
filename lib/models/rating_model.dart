import 'dart:convert';

// 將 JSON 列表字串轉換為 Rating 列表的輔助函式
List<Rating> ratingFromJson(String str) => List<Rating>.from(json.decode(str).map((x) => Rating.fromJson(x)));

class Rating {
  final String id;
  final String orderId;
  final int score;
  final String? comment;
  final DateTime createdAt;
  // 為了方便顯示，我們可以加入評價者的資訊
  final String? raterDisplayName;

  Rating({
    required this.id,
    required this.orderId,
    required this.score,
    this.comment,
    required this.createdAt,
    this.raterDisplayName,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      // 使用 .toString() 來確保任何類型都能被轉為字串
      id: json["id"]?.toString() ?? '',
      orderId: json["orderId"]?.toString() ?? '',
      raterDisplayName: json["raterDisplayName"]?.toString(),

      // score 維持原樣，因為它本來就應該是數字
      score: (json["score"] as num?)?.toInt() ?? 0,

      comment: json["comment"],
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"]) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}