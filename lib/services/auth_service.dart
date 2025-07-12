import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/secure_storage.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthService() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    final userData = await SecureStorage.getUserData();

    if (token != null && userData != null) {
      _user = User.fromJson(jsonDecode(userData));
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.login(username, password);
      
      await SecureStorage.storeToken(response['access_token']);
      await SecureStorage.storeUserData(jsonEncode(response['user']));

      _user = User.fromJson(response['user']);
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}