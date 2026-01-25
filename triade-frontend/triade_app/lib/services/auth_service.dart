import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/user.dart';

/// Serviço de autenticação responsável por:
/// - Armazenar/recuperar tokens de forma segura
/// - Realizar login, logout, registro
/// - Gerenciar sessão do usuário
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final String baseUrl = AppConstants.apiBaseUrl;

  // ==================== TOKEN MANAGEMENT ====================

  /// Salva os tokens de forma segura
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Recupera o access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Recupera o refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Salva dados do usuário
  Future<void> saveUserData(User user) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(user.toJson()));
  }

  /// Recupera dados do usuário salvos localmente
  Future<User?> getSavedUser() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  /// Remove todos os dados de autenticação
  Future<void> clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }

  /// Verifica se o usuário está logado (tem token salvo)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== AUTH OPERATIONS ====================

  /// Realiza login com email/username e senha
  Future<AuthResponse> login(String emailOrUsername, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailOrUsername,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final authResponse = AuthResponse.fromJson(data);
      
      // Salvar tokens e dados do usuário
      await saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await saveUserData(authResponse.user);
      
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Erro ao fazer login');
    }
  }

  /// Registra novo usuário
  Future<AuthResponse> register({
    required String username,
    required String personalName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'personal_name': personalName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final authResponse = AuthResponse.fromJson(data);
      
      // Salvar tokens e dados do usuário
      await saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await saveUserData(authResponse.user);
      
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw AuthException(
        error['error'] ?? 'Erro ao registrar',
        field: error['field'],
      );
    }
  }

  /// Renova o access token usando o refresh token
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (e) {
      // Falha silenciosa
    }
    
    return false;
  }

  /// Busca dados do usuário autenticado
  Future<User> getCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) {
      throw AuthException('Não autenticado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final user = User.fromJson(data['user']);
      await saveUserData(user);
      return user;
    } else if (response.statusCode == 401) {
      // Token expirado, tentar refresh
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        return getCurrentUser();
      }
      throw AuthException('Sessão expirada');
    } else {
      throw AuthException('Erro ao buscar dados do usuário');
    }
  }

  /// Realiza logout
  Future<void> logout() async {
    await clearAuthData();
  }

  // ==================== VALIDAÇÃO ====================

  /// Verifica disponibilidade do username
  Future<bool> checkUsernameAvailable(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/check-username/$username'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] as bool;
    }
    return false;
  }

  /// Verifica disponibilidade do email
  Future<bool> checkEmailAvailable(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/check-email/$email'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] as bool;
    }
    return false;
  }

  // ==================== FOTO DE PERFIL ====================

  /// Upload de foto de perfil (aceita File ou String base64)
  Future<void> uploadProfilePhoto(dynamic photo) async {
    final token = await getAccessToken();
    if (token == null) throw AuthException('Não autenticado');

    String base64Photo;
    if (photo is String) {
      base64Photo = photo;
    } else {
      // É um File, converter para base64 com prefixo
      final bytes = await photo.readAsBytes();
      base64Photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/me/photo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'photo': base64Photo}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Erro ao enviar foto');
    }
    
    // Atualizar dados do usuário localmente após upload
    final user = await getCurrentUser();
    await saveUserData(user);
  }

  // ==================== EDITAR PERFIL ====================

  /// Atualiza o perfil do usuário (nome e email)
  Future<void> updateProfile({
    required String personalName,
    required String email,
  }) async {
    final token = await getAccessToken();
    if (token == null) throw AuthException('Não autenticado');

    final response = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'personal_name': personalName,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Erro ao atualizar perfil');
    }

    // Atualizar dados salvos localmente
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['user'] != null) {
      await saveUserData(User.fromJson(data['user']));
    }
  }

  // ==================== ALTERAR SENHA ====================

  /// Altera a senha do usuário
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getAccessToken();
    if (token == null) throw AuthException('Não autenticado');

    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Erro ao alterar senha');
    }
  }

  // ==================== RECUPERAR SENHA ====================

  /// Solicita recuperação de senha por email
  Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Erro ao solicitar recuperação');
    }
  }

  /// URL da foto de perfil do usuário atual
  Future<String?> getProfilePhotoUrl() async {
    final token = await getAccessToken();
    if (token == null) return null;
    return '$baseUrl/auth/me/photo';
  }

  /// URL da foto de perfil de um usuário específico
  String getUserPhotoUrl(String username) {
    return '$baseUrl/auth/users/$username/photo';
  }
}

/// Exceção customizada para erros de autenticação
class AuthException implements Exception {
  final String message;
  final String? field;

  AuthException(this.message, {this.field});

  @override
  String toString() => message;
}
