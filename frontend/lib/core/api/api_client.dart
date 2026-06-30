import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ApiClient centralizado con Dio — equivalente a una instancia axios configurada.
/// Maneja: base URL, JWT en headers, refresh automático de token, errores globales.
class ApiClient {
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5000/api');

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor: adjunta el Bearer token a cada request (como axios interceptors)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Refresh automático si el token expiró (401)
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Reintenta la petición original con el nuevo token
              final newToken = await _getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─── Token management ──────────────────────────────────────────────────────

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$_baseUrl/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      final newAccess = response.data['access_token'] as String;
      await prefs.setString(_accessKey, newAccess);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  // ─── HTTP methods (misma API que axios) ───────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

/// Singleton global — importar este en cualquier provider/service
final apiClient = ApiClient();
