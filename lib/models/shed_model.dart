import 'dart:convert';

List<Shed> shedFromJson(String str) {
  final jsonData = json.decode(str);
  final List<dynamic> shedList =
      jsonData['data']; // Assuming same API structure
  return List<Shed>.from(shedList.map((x) => Shed.fromJson(x)));
}

class Shed {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String locationId; // Foreign key
  Shed({
    required this.id,
    required this.name,
    required this.code,
    required this.locationId,
    this.description,
  });

  factory Shed.fromJson(Map<String, dynamic> json) => Shed(
    id: json["id"],
    name: json["name"],
    code: json["code"],
    description: json["description"],
    locationId: json["location_id"],
  );
}
