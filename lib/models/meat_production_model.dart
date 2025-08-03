import 'dart:convert';

List<MeatProduction> meatProductionFromJson(String str) {
  // First, decode the entire JSON string into a Map
  final jsonData = json.decode(str);

  // IMPORTANT: Access the list of farms from the 'data' key.
  // If your Laravel API uses a different key, change 'data' to that key.
  final List<dynamic> meatProductionList = jsonData['data'];

  // Now, map over the correct listLocation
  return List<MeatProduction>.from(
    meatProductionList.map((x) => MeatProduction.fromJson(x)),
  );
}

class MeatProduction {
  final int id;
  final String flockId;
  final String flockName; // Useful to have from a backend JOIN
  final String date;
  final String totalMeatCount;
  final String totalMeatWeight;
  final String? deathCount;
  final String feedAmount;
  final String waterAmount;

  MeatProduction({
    required this.id,
    required this.flockId,
    required this.flockName,
    required this.totalMeatCount,
    required this.totalMeatWeight,
    this.deathCount,
    required this.feedAmount,
    required this.waterAmount,
    required this.date,
  });

  factory MeatProduction.fromJson(Map<String, dynamic> json) => MeatProduction(
    id: json["id"],
    flockId: json["flock_id"],
    flockName: json["flock"]?['name'] ?? 'Unknown Flock',
    totalMeatCount: json["total_chicken_count"],
    totalMeatWeight: json["total_chicken_weight"],
    deathCount: json["death_count"] ?? "0",
    feedAmount: json["feed_amount"],
    waterAmount: json["water_amount"],
    date: json["date"],
  );
}
