import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por gerenciar o estado do tutorial onboarding
/// Utiliza SharedPreferences para persistir se o usuário já completou o tutorial
class OnboardingService {
  static const String _hasSeenTutorialKey = 'has_seen_onboarding_tutorial';
  static const String _tutorialVersionKey = 'onboarding_tutorial_version';
  
  // Versão atual do tutorial - incrementar quando houver mudanças significativas
  static const int _currentTutorialVersion = 1;

  /// Verifica se o usuário já completou o tutorial
  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_hasSeenTutorialKey) ?? false;
    final seenVersion = prefs.getInt(_tutorialVersionKey) ?? 0;
    
    // Se a versão do tutorial mudou, mostrar novamente
    if (seenVersion < _currentTutorialVersion) {
      return false;
    }
    
    return hasSeen;
  }

  /// Marca o tutorial como completado
  static Future<void> markTutorialAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTutorialKey, true);
    await prefs.setInt(_tutorialVersionKey, _currentTutorialVersion);
  }

  /// Reseta o estado do tutorial (para permitir ver novamente)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTutorialKey, false);
  }

  /// Verifica se deve mostrar o tutorial automaticamente no primeiro login
  static Future<bool> shouldShowTutorialOnLogin() async {
    return !(await hasCompletedTutorial());
  }
}
