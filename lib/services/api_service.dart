import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/secure_storage.dart';
import '../models/user.dart';
import '../models/payment.dart';
import '../models/dashboard_stats.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String username, String password) async {
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Dashboard endpoints
  static Future<DashboardStats> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return DashboardStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch dashboard stats');
    }
  }

  static Future<List<RevenueChartData>> getRevenueChart([int days = 7]) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/revenue-chart?days=$days'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => RevenueChartData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch revenue chart data');
    }
  }

  // Payment endpoints
  static Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int limit = 10,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status.name;
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod.name;
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final uri = Uri.parse('$baseUrl/payments').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'payments': (data['payments'] as List)
            .map((item) => Payment.fromJson(item))
            .toList(),
        'total': data['total'],
      };
    } else {
      throw Exception('Failed to fetch payments');
    }
  }

  static Future<Payment> getPayment(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Payment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch payment');
    }
  }

  static Future<Payment> createPayment({
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
    required String receiverName,
    String? receiverEmail,
    String? description,
    PaymentStatus status = PaymentStatus.pending,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod.name,
        'receiver_name': receiverName,
        'receiver_email': receiverEmail,
        'description': description,
        'status': status.name,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Payment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create payment: ${response.body}');
    }
  }

  // User endpoints
  static Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  static Future<User> createUser({
    required String username,
    required String email,
    required String password,
    String role = 'viewer',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }
}