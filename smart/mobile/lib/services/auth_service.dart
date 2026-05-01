import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  AuthService(this.api);

  final ApiService api;
  Map<String, dynamic>? user;

  bool get isAuthenticated => user != null;

  /// LOGIN WITH EMAIL OR PHONE
  Future<void> login(
    String emailOrPhone,
    String password, {
    String? expectedRole,
  }) async {
    final input = emailOrPhone.trim();

    if (input.isEmpty) {
      throw Exception('Email or phone number is required');
    }

    if (password.isEmpty) {
      throw Exception('Password is required');
    }

    final bool isEmail = input.contains('@');
    final Map<String, String> body = {'password': password};

    if (isEmail) {
      final emailRegex =
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(input)) {
        throw Exception('Enter a valid email address');
      }
      body['email'] = input;
    } else {
      final phone = _normalizePhone(input);
      if (phone.length < 10) {
        throw Exception('Enter a valid phone number');
      }
      body['phone'] = phone;
    }

    try {
      final res = await api.post('/auth/login', body);
      final payload = res['data'] as Map<String, dynamic>;

      user = payload['user'];

      if (expectedRole != null && (user?['role']?.toString() != expectedRole)) {
        throw Exception('This account is not authorized for ${expectedRole.toUpperCase()} login');
      }

      api.token = payload['token'];
      notifyListeners();
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      final lower = message.toLowerCase();

      if (lower.contains('failed host lookup') ||
          lower.contains('socketexception') ||
          lower.contains('connection refused') ||
          lower.contains('network') ||
          lower.contains('timeout')) {
        throw Exception(
          'Cannot reach server at ${api.baseUrl}. Check backend and API URL. If using a real phone, do not use localhost; use your PC LAN IP (e.g. 192.168.x.x).'
        );
      }

      throw Exception(message.isEmpty ? 'Login failed' : message);
    }
  }

  /// REGISTER - CITIZEN
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final normalizedPhone = _normalizePhone(phone);

    if (name.trim().isEmpty) {
      throw Exception('Full name is required');
    }
    if (!email.contains('@')) {
      throw Exception('Enter a valid email address');
    }
    if (normalizedPhone.length < 10) {
      throw Exception('Enter a valid phone number');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    final res = await api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': normalizedPhone,
      'password': password,
      'role': 'citizen',
    });

    final payload = res['data'] as Map<String, dynamic>;
    user = payload['user'];
    api.token = payload['token'];
    notifyListeners();
  }

  /// REGISTER - ADMIN
  Future<void> registerAdmin(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final normalizedPhone = _normalizePhone(phone);

    if (name.trim().isEmpty) {
      throw Exception('Full name is required');
    }
    if (!email.contains('@')) {
      throw Exception('Enter a valid email address');
    }
    if (normalizedPhone.length < 10) {
      throw Exception('Enter a valid phone number');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    final res = await api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': normalizedPhone,
      'password': password,
      'role': 'admin',
    });

    final payload = res['data'] as Map<String, dynamic>;
    user = payload['user'];
    api.token = payload['token'];
    notifyListeners();
  }

  /// REGISTER - DEPARTMENT
  Future<void> registerDepartment(
    String contactName,
    String email,
    String phone,
    String password,
    String departmentType,
  ) async {
    final normalizedPhone = _normalizePhone(phone);

    if (contactName.trim().isEmpty) {
      throw Exception('Full name is required');
    }
    if (!email.contains('@')) {
      throw Exception('Enter a valid email address');
    }
    if (normalizedPhone.length < 10) {
      throw Exception('Enter a valid phone number');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }
    if (departmentType.trim().isEmpty) {
      throw Exception('Department type is required');
    }

    final res = await api.post('/auth/register', {
      'name': contactName.trim(),
      'email': email.trim(),
      'phone': normalizedPhone,
      'password': password,
      'role': 'department',
      'department_type': departmentType.trim(),
    });

    final payload = res['data'] as Map<String, dynamic>;
    user = payload['user'];
    api.token = payload['token'];
    notifyListeners();
  }

  String _normalizePhone(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  /// UPDATE PROFILE
  Future<void> updateProfile(String name, String email, String phone) async {
    if (name.trim().isEmpty) {
      throw Exception('Name is required');
    }

    if (!email.contains('@')) {
      throw Exception('Enter a valid email address');
    }

    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.length < 10) {
      throw Exception('Enter a valid phone number');
    }

    final res = await api.put('/auth/profile', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': normalizedPhone,
    });

    final payload = res['data'] as Map<String, dynamic>;
    user = payload;
    notifyListeners();
  }

  void logout() {
    user = null;
    api.token = null;
    notifyListeners();
  }
}
