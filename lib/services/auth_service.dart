import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();

  // The ONLY place we read from storage.
  // We add a manual delay as a final safeguard.
  Future<String?> getInitialToken() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return await _storage.read(key: 'token');
  }

  Future<String> login(String email, String password) async {
    final token = await _apiService.login(email, password);
    await _storage.write(key: 'token', value: token);
    return token;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
}
