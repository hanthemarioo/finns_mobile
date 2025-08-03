import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  // This is now the ONLY way to change the token.
  void setAuthToken(String? newToken) {
    _token = newToken;
    notifyListeners();
  }
}