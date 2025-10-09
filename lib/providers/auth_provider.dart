// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kenuniv/utils/constant.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;

  AuthState({this.isLoading = false, this.error, this.token});

  AuthState copyWith({bool? isLoading, String? error, String? token}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      token: token ?? this.token,
    );
  }

  /// Helper getter to access token directly
  String get authToken => token ?? '';
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> login(String mobile, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse(adminLoginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"mobile": mobile, "password": password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["token"] != null) {
        // ✅ store token in state
        state = state.copyWith(token: data["token"]);
        return true;
      } else {
        state = state.copyWith(error: data["message"] ?? "Login failed");
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ✅ Optional: logout to clear token
  void logout() {
    state = AuthState();
  }
}
