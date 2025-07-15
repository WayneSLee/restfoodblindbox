// lib/models/customer_profile_model.dart

class CustomerProfile {
  final String? name;
  final double averageRating;
  final int totalRatings;

  CustomerProfile({
    this.name,
    required this.averageRating,
    required this.totalRatings,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      name: json["name"],
      averageRating: (json["averageRating"] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json["totalRatings"] as num?)?.toInt() ?? 0,
    );
  }
}