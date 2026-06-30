import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.unknown;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      final res = await apiClient.get('/users/me');
      _user = AppUser.fromJson(res.data as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _error = null;
    try {
      final res = await apiClient.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      await _handleAuthResponse(res.data as Map<String, dynamic>);
      return true;
    } on DioException catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    _error = null;
    try {
      final res = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _handleAuthResponse(res.data as Map<String, dynamic>);
      return true;
    } on DioException catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await apiClient.clearTokens();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ─── Update profile ────────────────────────────────────────────────────────

  Future<bool> updateProfile({String? name, String? avatarUrl}) async {
    _error = null;
    try {
      final res = await apiClient.put('/users/me', data: {
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      _user = AppUser.fromJson(res.data as Map<String, dynamic>);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    await apiClient.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ?? 'Error desconocido';
    }
    return e.message ?? 'Error de conexión';
  }
}
