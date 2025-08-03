import 'dart:convert';

// This function will be used inside the wrapper model
List<EggProduction> eggProductionFromJson(String str) {
  // First, decode the entire JSON string into a Map
  final jsonData = json.decode(str);

  // IMPORTANT: Access the list of farms from the 'data' key.
  // If your Laravel API uses a different key, change 'data' to that key.
  final List<dynamic> eggProductionList = jsonData['data'];

  // Now, map over the correct listLocation
  return List<EggProduction>.from(eggProductionList.map((x) => EggProduction.fromJson(x)));
}

class EggProduction {
  final int id;
  final String flockId;
  final String flockName; // Useful to have from a backend JOIN
  final String date;
  final String totalEggCount;
  final String totalEggWeight;
  final String? deathCount;
  final String feedAmount;
  final String waterAmount;

  EggProduction({
    required this.id,
    required this.flockId,
    required this.flockName,
    required this.totalEggCount,
    required this.totalEggWeight,
    this.deathCount,
    required this.feedAmount,
    required this.waterAmount,
    required this.date,
  });

  factory EggProduction.fromJson(Map<String, dynamic> json) => EggProduction(
    id: json["id"],
    flockId: json["flock_id"],
    flockName: json["flock"]?['name'] ?? 'Unknown Flock',
    totalEggCount: json["total_egg_count"],
    totalEggWeight: json["total_egg_weight"],
    deathCount: json["death_count"] ?? "0",
    feedAmount: json["feed_amount"],
    waterAmount: json["water_amount"],
    date: json["date"],
  );
}
