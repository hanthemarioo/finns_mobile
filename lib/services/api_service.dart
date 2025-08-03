import 'dart:convert';
import 'package:finns_mobile/models/egg_production_model.dart';
import 'package:finns_mobile/models/flock_model.dart';
import 'package:finns_mobile/models/meat_production_model.dart';
import 'package:finns_mobile/models/shed_model.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class ApiService {
  static const String _baseUrl = 'https://api-farm.mrkondang.my.id/api/';

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // IMPORTANT: Adjust 'token' key based on your Laravel API response
      if (data.containsKey('access_token')) {
        return data['access_token'];
      } else {
        throw Exception('Token not found in response');
      }
    } else {
      // Handle login errors (e.g., 401 Unauthorized)
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to login');
    }
  }

  Future<List<Location>> getLocations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}location'),
        // Send token in the header
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return locationFromJson(response.body);
      } else {
        // Handle token errors (e.g., 401 Unauthenticated)
        throw Exception(
          'Failed to load locations (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch locations: $e');
    }
  }

  Future<void> createLocation({
    required String token,
    required String name,
    required String address,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${_baseUrl}location',
      ), // Assumes your create endpoint is POST /api/location
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'address': address,
        'description': description,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      // For debugging, print the actual status code and body
      print('Failed with status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create location.');
    }
  }

  Future<void> updateLocation({
    required String token,
    required String name,
    required String address,
    String? description,
    required int locationId,
  }) async {
    final response = await http.put(
      Uri.parse('${_baseUrl}location/$locationId'), // Note the ID in the URL
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'address': address,
        'description': description,
      }),
    );

    // A successful update often returns a 200 OK status code.
    if (response.statusCode != 200) {
      // For debugging
      print('Failed with status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update location.');
    }
  }

  Future<List<Shed>> getSheds(String token, int locationId) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}get-sheds-by-location-id/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return shedFromJson(response.body); // Uses the shed_model.dart parser
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception(
          'Failed to load sheds (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch sheds: $e');
    }
  }

  Future<void> createShed({
    required String token,
    required int locationId, // The ID of the parent location
    required String name,
    required String code,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}shed'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'location_id': locationId,
        'code': code,
        'description': description,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create shed.');
    }
  }

  // --- UPDATE Shed ---
  // Your Laravel route would be: Route::put('/sheds/{shed}', ...)
  Future<void> updateShed({
    required String token,
    required int shedId, // The ID of the shed itself
    required int locationId, // The ID of the parent location
    required String name,
    required String code,
    String? description,
  }) async {
    final response = await http.put(
      Uri.parse('${_baseUrl}shed/$shedId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'location_id': locationId,
        'code': code,
        'description': description,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update shed.');
    }
  }

  Future<List<Flock>> getFlocksForLocation(String token, int locationId) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}get-flocks-by-location-id/$locationId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) return flockFromJson(response.body);
    if (response.statusCode == 404) return [];
    throw Exception('Failed to load flocks');
  }

  // --- CREATE Flock ---
  // Laravel Route: Route::post('/flocks', ...)
  Future<void> createFlock({
    required String token,
    required String shedId, // The crucial foreign key
    required String name,
    required String code,
    required String startDate,
    required String faseType,
    required int initialPopulation,
    required String breed,
    required String gender,
    required String source,
    required int? ageOnArrival,
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}flock'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'shed_id': shedId,
        'name': name,
        'code': code,
        'start_date': startDate,
        'fase_type': faseType,
        'initial_population': initialPopulation,
        'breed': breed,
        'gender': gender,
        'source': source,
        'age_on_arrival': ageOnArrival,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create flock.');
    }
  }

  Future<void> updateFlock({
    required String token,
    required int flockId,
    required String shedId, // The crucial foreign key
    required String name,
    required String code,
    required String startDate,
    required String faseType,
    required int initialPopulation,
    required String breed,
    required String gender,
    required String source,
    required int? ageOnArrival,
  }) async {
    final response = await http.put(
      Uri.parse('${_baseUrl}flock/$flockId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'shed_id': shedId,
        'name': name,
        'code': code,
        'start_date': startDate,
        'fase_type': faseType,
        'initial_population': initialPopulation,
        'breed': breed,
        'gender': gender,
        'source': source,
        'age_on_arrival': ageOnArrival,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update flock.');
    }
  }

  Future<List<Flock>> getFlock(String token) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}flock'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // We can reuse the flockFromJson parser from the flock model
      return flockFromJson(response.body);
    } else {
      throw Exception('Failed to load user flocks.');
    }
  }

  // --- NEW: Method for Egg Production ---
  // Assumes endpoint is GET /api/egg-production, scoped to the user by the token
  Future<List<EggProduction>> getEggProductions(String token) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}egg-production'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    print("Response body Egg: ${response.body}");

    if (response.statusCode == 200) {
      // Use the model parser directly
      return eggProductionFromJson(response.body);
    } else {
      throw Exception('Failed to load egg production data.');
    }
  }

  // --- NEW: Method for Meat Production ---
  // Assumes endpoint is GET /api/meat-production
  Future<List<MeatProduction>> getMeatProductions(String token) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}meat-production'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    print("Response Body Meat: ${response.body}");

    if (response.statusCode == 200) {
      return meatProductionFromJson(response.body);
    } else {
      throw Exception('Failed to load meat production data.');
    }
  }

  Future<void> createEggProduction({
    required String token,
    required String flockId,
    required String date,
    required int totalEggCount,
    required int totalEggWeight,
    required int feedAmount,
    required int waterAmount,
    required int? deathCount,
    // required DateTime date, // The backend usually handles the date
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}egg-production'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'flock_id': flockId,
        'date': date,
        'total_egg_count': totalEggCount,
        'total_egg_weight': totalEggWeight,
        'feed_amount': feedAmount,
        'water_amount': waterAmount,
        'death_count': deathCount,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create egg production.');
    }
  }

  // --- CREATE Meat Production ---
  // Your Laravel Route: Route::post('/meat-productions', ...)
  Future<void> updateEggProduction({
    required String token,
    required int eggProductionId,
    required String flockId,
    required String date,
    required int totalEggCount,
    required int totalEggWeight,
    required int feedAmount,
    required int waterAmount,
    required int? deathCount,
  }) async {
    final response = await http.put(
      Uri.parse('${_baseUrl}egg-production/$eggProductionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'flock_id': flockId,
        'date': date,
        'total_egg_count': totalEggCount,
        'total_egg_weight': totalEggWeight,
        'feed_amount': feedAmount,
        'water_amount': waterAmount,
        'death_count': deathCount,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create meat production.');
    }
  }

  Future<void> createMeatProduction({
    required String token,
    required String flockId,
    required String date,
    required int totalMeatCount,
    required int totalMeatWeight,
    required int feedAmount,
    required int waterAmount,
    required int? deathCount,
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}meat-production'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'flock_id': flockId,
        'date': date,
        'total_chicken_count': totalMeatCount,
        'total_chicken_weight': totalMeatWeight,
        'feed_amount': feedAmount,
        'water_amount': waterAmount,
        'death_count': deathCount,
      }),
    );
    print("Response Body: ${response.body}");
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create meat production.');
    }
  }

  Future<void> updateMeatProduction({
    required String token,
    required int meatProductionId,
    required String flockId,
    required String date,
    required int totalMeatCount,
    required int totalMeatWeight,
    required int feedAmount,
    required int waterAmount,
    required int? deathCount,
  }) async {
    final response = await http.put(
      Uri.parse('${_baseUrl}meat-production/$meatProductionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'flock_id': flockId,
        'date': date,
        'total_chicken_count': totalMeatCount,
        'total_chicken_weight': totalMeatWeight,
        'feed_amount': feedAmount,
        'water_amount': waterAmount,
        'death_count': deathCount,
      }),
    );
    print("Response Body: ${response.body}");
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create meat production.');
    }
  }
}
