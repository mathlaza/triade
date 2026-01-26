import 'package:audioplayers/audioplayers.dart';

/// Serviço singleton para reproduzir sons de feedback
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal() {
    _init(); // Auto-inicializa ao criar instância
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  static final _clickSource = AssetSource('sounds/click.wav');

  /// Inicializa e pré-carrega o som
  Future<void> _init() async {
    if (_isInitialized) return;
    
    try {
      // Configura para baixa latência
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setVolume(0.5);
      
      // Pré-carrega o som (toca mudo para cachear)
      await _player.setSource(_clickSource);
      
      _isInitialized = true;
    } catch (e) {
      // Ignora erros de inicialização
    }
  }

  /// Toca o som de click instantaneamente
  void playClick() {
    // Usa unawaited para não bloquear - som é fire-and-forget
    _player.resume().catchError((_) {});
    
    // Re-prepara para próximo clique
    Future.delayed(const Duration(milliseconds: 100), () {
      _player.stop().then((_) => _player.setSource(_clickSource));
    });
  }

  /// Libera recursos (chamar ao fechar o app se necessário)
  Future<void> dispose() async {
    await _player.dispose();
  }
}
