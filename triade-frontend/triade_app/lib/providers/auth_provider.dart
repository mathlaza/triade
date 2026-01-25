import 'package:flutter/foundation.dart';
import 'package:triade_app/models/user.dart';
import 'package:triade_app/services/auth_service.dart';

/// Estado de autenticação do app
enum AuthStatus {
  unknown,    // Estado inicial, verificando se há token salvo
  authenticated,  // Usuário logado
  unauthenticated,  // Usuário não logado
}

/// Provider de autenticação
/// Gerencia o estado de login/logout e dados do usuário
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Inicializa o provider verificando se há sessão salva
  Future<void> init() async {
    _status = AuthStatus.unknown;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Tentar recuperar dados do usuário
        try {
          _user = await _authService.getCurrentUser();
          _status = AuthStatus.authenticated;
        } catch (e) {
          // Token inválido ou expirado, tentar refresh
          final refreshed = await _authService.refreshAccessToken();
          if (refreshed) {
            _user = await _authService.getCurrentUser();
            _status = AuthStatus.authenticated;
          } else {
            // Refresh falhou, limpar dados
            await _authService.clearAuthData();
            _status = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Realiza login
  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(emailOrUsername, password);
      _user = response.user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro de conexão. Verifique sua internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Realiza registro
  Future<bool> register({
    required String username,
    required String personalName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        username: username,
        personalName: personalName,
        email: email,
        password: password,
      );
      _user = response.user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro de conexão. Verifique sua internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Realiza logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Atualiza dados do usuário
  Future<void> refreshUser() async {
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Upload de foto de perfil (aceita File ou String base64)
  Future<bool> uploadProfilePhoto(dynamic photo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.uploadProfilePhoto(photo);
      await refreshUser();
      // Invalidar cache da foto para forçar reload
      _photoTimestamp = DateTime.now().millisecondsSinceEpoch;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao enviar foto';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Atualiza perfil do usuário (nome e email)
  Future<void> updateProfile({
    required String personalName,
    required String email,
  }) async {
    await _authService.updateProfile(
      personalName: personalName,
      email: email,
    );
    await refreshUser();
  }

  /// Altera a senha do usuário
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Limpa mensagem de erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifica disponibilidade do username
  Future<bool> checkUsernameAvailable(String username) {
    return _authService.checkUsernameAvailable(username);
  }

  /// Verifica disponibilidade do email
  Future<bool> checkEmailAvailable(String email) {
    return _authService.checkEmailAvailable(email);
  }

  /// Timestamp para cache-busting da foto de perfil
  int _photoTimestamp = DateTime.now().millisecondsSinceEpoch;

  /// URL da foto de perfil com cache-busting
  String? get profilePhotoUrl {
    if (_user?.hasPhoto == true) {
      return '${_authService.getUserPhotoUrl(_user!.username)}?t=$_photoTimestamp';
    }
    return null;
  }

  /// Força atualização do timestamp da foto (para invalidar cache)
  void invalidatePhotoCache() {
    _photoTimestamp = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }
}
