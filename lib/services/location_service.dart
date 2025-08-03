import 'package:finns_mobile/models/location_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final String baseUrl =
      'https://api-farm.mrkondang.my.id/api/'; // Ganti dengan base URL milikmu

  // Mendapatkan daftar location
  Future<List<Location>> getLocations(String token) async {
    final response = await http.get(
      Uri.parse('${baseUrl}location'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Decoding JSON yang berisi Map, bukan langsung List
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Mengakses bagian 'data' yang berisi list location
      final List<dynamic> locationsJson = data['data'];

      // Mengonversi data menjadi objek Location
      return locationsJson.map((json) => Location.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil daftar location');
    }
  }
}
