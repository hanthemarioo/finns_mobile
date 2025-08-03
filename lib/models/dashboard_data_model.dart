import 'dart:convert';

// This function will be used inside the wrapper model
DashboardData dashboardDataFromJson(String str) {
  // Now, map over the correct listLocation
  return DashboardData.fromJson(json.decode(str));
}

// Main wrapper class for the entire dashboard response
class DashboardData {
  final ProductionSummary eggProduction;
  final ProductionSummary meatProduction;
  final DateRange range;

  DashboardData({
    required this.eggProduction,
    required this.meatProduction,
    required this.range,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    eggProduction: ProductionSummary.fromJson(json["egg_production"]),
    meatProduction: ProductionSummary.fromJson(json["meat_production"]),
    range: DateRange.fromJson(json["range"]),
  );
}

// A reusable class for both egg and meat production summaries
class ProductionSummary {
  final String totalCount;
  final String totalWeight;
  final String totalFeed;
  final String totalWater;
  final String totalDeath;
  final String fcr;

  ProductionSummary({
    required this.totalCount,
    required this.totalWeight,
    required this.totalFeed,
    required this.totalWater,
    required this.totalDeath,
    required this.fcr,
  });

  factory ProductionSummary.fromJson(Map<String, dynamic> json) =>
      ProductionSummary(
        // Using ?? '0' as a fallback in case any value is unexpectedly null
        totalCount:
            json["total_egg_count"] ?? json["total_chicken_count"] ?? '0',
        totalWeight:
            json["total_egg_weight"] ?? json["total_chicken_weight"] ?? '0',
        totalFeed: json["total_feed"] ?? '0',
        totalWater: json["total_water"] ?? '0',
        totalDeath: json["total_death"] ?? '0',
        fcr: json["fcr"] ?? '0.0',
      );
}

// Class for the date range
class DateRange {
  final String from;
  final String to;

  DateRange({required this.from, required this.to});

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      DateRange(from: json["from"], to: json["to"]);
}
