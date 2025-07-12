import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'https://showpay-backend.onrender.com';
  static const String apiVersion = '/api/v1';
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String userDataKey = 'user_data';
}

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFF9800);
  static const Color pending = Color(0xFFFFA500);
}