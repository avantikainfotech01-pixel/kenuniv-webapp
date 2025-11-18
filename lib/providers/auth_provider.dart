// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kenuniv/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;
  final Map<String, dynamic>? permissions;
  final String? role;

  AuthState({
    this.isLoading = false,
    this.error,
    this.token,
    this.permissions,
    this.role,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? token,
    Map<String, dynamic>? permissions,
    String? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      token: token ?? this.token,
      permissions: permissions ?? this.permissions,
      role: role ?? this.role,
    );
  }

  /// Helper getter to access token directly
  String get authToken => token ?? '';
  String get userRole => role ?? '';
  bool hasPermission(String key) => permissions?[key] == true;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await loadAuthData();
  }

  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final permissionsString = prefs.getString('permissions');

    if (token != null && role != null && permissionsString != null) {
      final permissions = Map<String, dynamic>.from(
        jsonDecode(permissionsString),
      );
      state = state.copyWith(
        token: token,
        role: role,
        permissions: permissions,
      );
      print('🔁 Restored session: role=$role, permissions=$permissions');
    } else {
      print('⚠️ No saved session found during restore');
    }
  }

  Future<bool> login(String mobile, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse(adminLoginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"mobile": mobile, "password": password}),
      );

      final data = jsonDecode(response.body);
      // Clear any existing session before storing new login data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Save token, permissions, role if login succeeds
      if (response.statusCode == 200 && data["token"] != null) {
        final user = data["user"] ?? {};
        state = state.copyWith(
          token: data["token"],
          permissions: Map<String, dynamic>.from(user["permissions"] ?? {}),
          role: user["role"],
        );
        await prefs.setString('token', data["token"]);
        await prefs.setString('role', user["role"] ?? '');
        await prefs.setString(
          'permissions',
          jsonEncode(user["permissions"] ?? {}),
        );
        print(
          '✅ Login successful: role=${user["role"]}, permissions=${user["permissions"]}',
        );
        return true;
      } else {
        state = state.copyWith(error: data["message"] ?? "Login failed");
        print('❌ Login failed: ${data["message"] ?? "Unknown error"}');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      print('❌ Login exception: $e');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ✅ Optional: logout to clear token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = AuthState();
    print('🚪 Logged out and cleared all saved session data');
  }
}
