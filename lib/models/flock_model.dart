import 'dart:convert';

List<Flock> flockFromJson(String str) {
  final jsonData = json.decode(str);
  final List<dynamic> flockList = jsonData['data']; // Assuming same API structure
  return List<Flock>.from(flockList.map((x) => Flock.fromJson(x)));
}

class Flock {
    final int id;
    final String shedId; // Foreign key
    final String name;
    final String code;
    final String startDate;
    final String faseType;
    final String initialPopulation;
    final String breed;
    final String gender;
    final String? source;
    final String? ageOnArrival;

    Flock({
        required this.id,
        required this.shedId,
        required this.name,
        required this.startDate,
        required this.code,
        required this.faseType,
        required this.initialPopulation,
        required this.breed,
        required this.gender,
        this.source,
        this.ageOnArrival,
    });

    factory Flock.fromJson(Map<String, dynamic> json) => Flock(
        id: json["id"],
        name: json["name"],
        code: json["code"],
        startDate: json["start_date"],
        faseType: json["fase_type"],
        initialPopulation: json["initial_population"],
        breed: json["breed"],
        gender: json["gender"],
        source: json["source"],
        ageOnArrival: json["age_on_arrival"],
        shedId: json["shed_id"],
    );
}