import 'dart:convert';

// REPLACE THE OLD FUNCTION WITH THIS ONE
List<Location> locationFromJson(String str) {
  // First, decode the entire JSON string into a Map
  final jsonData = json.decode(str);

  // IMPORTANT: Access the list of farms from the 'data' key.
  // If your Laravel API uses a different key, change 'data' to that key.
  final List<dynamic> locationList = jsonData['data'];

  // Now, map over the correct listLocation
  return List<Location>.from(locationList.map((x) => Location.fromJson(x)));
}
// THE REST OF THE FILE (Farm class) REMAINS THE SAME
// ...
class Location {
    final int id;
    final String name;
    final String address;
    final String? description;

    Location({
        required this.id,
        required this.name,
        required this.address,
        this.description,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json["id"],
        name: json["name"],
        address: json["address"],
        description: json["description"],
    );
}