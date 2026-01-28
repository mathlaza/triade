import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/providers/config_provider.dart';
import 'package:triade_app/providers/auth_provider.dart';
import 'package:triade_app/screens/home_screen.dart';
import 'package:triade_app/screens/login_screen.dart';
import 'package:triade_app/services/sound_service.dart';
import 'package:triade_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pré-carrega o serviço de som para evitar delay no primeiro clique
  SoundService();

  // Inicializa notificações ANTES de tudo para garantir permissões em release
  // Isso é crítico porque em release mode a inicialização tardia pode falhar
  await NotificationService().init();

  // Configura a barra de status para modo dark
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializa Sentry para monitoramento de erros
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://49f80413318b55a7bee8964ae5d3a093@o4510784716603392.ingest.us.sentry.io/4510784796229632';
      options.tracesSampleRate = 1.0;
      options.sendDefaultPii = true;
    },
    appRunner: () => runApp(const TriadeApp()),
  );
}

class TriadeApp extends StatelessWidget {
  const TriadeApp({super.key});

  // Premium Dark Theme Colors
  static const _backgroundColor = Color(0xFF000000);
  static const _surfaceColor = Color(0xFF1C1C1E);
  static const _goldAccent = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
      ],
      child: MaterialApp(
        title: 'Tríade da Energia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: _goldAccent,
          scaffoldBackgroundColor: _backgroundColor,
          colorScheme: const ColorScheme.dark(
            primary: _goldAccent,
            secondary: _goldAccent,
            surface: _surfaceColor,
          ),
          useMaterial3: true,
          // Tema do TimePicker com melhor contraste e indicação de seleção
          timePickerTheme: TimePickerThemeData(
            backgroundColor: _surfaceColor,
            dialBackgroundColor: _backgroundColor,
            // Cor dos campos de hora/minuto - muda quando selecionado
            hourMinuteColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _goldAccent; // Amarelo quando selecionado
              }
              return const Color(
                  0xFF2C2C2E); // Cinza escuro quando não selecionado
            }),
            hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.black; // Preto no fundo amarelo
              }
              return Colors.white70; // Branco no fundo cinza
            }),
            // AM/PM
            dayPeriodColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _goldAccent;
              }
              return const Color(0xFF2C2C2E);
            }),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.black;
              }
              return Colors.white70;
            }),
            // Dial (relógio)
            dialHandColor: _goldAccent,
            dialTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.black; // Preto quando selecionado (fundo amarelo)
              }
              return Colors.white; // Branco quando não selecionado
            }),
            entryModeIconColor: _goldAccent,
            helpTextStyle: const TextStyle(color: Colors.white70),
            padding: const EdgeInsets.all(24),
            // Cursor preto para visibilidade no modo de entrada por teclado
            hourMinuteTextStyle: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
            // Tema do campo de texto no modo de entrada por teclado
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              // Cursor fica visível porque o texto é preto no fundo amarelo
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
          // Cor do cursor global - preto para campos com fundo claro
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: Colors.black.withValues(alpha: 0.3),
            selectionHandleColor: Colors.black,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Widget que gerencia o estado de autenticação
/// Mostra tela de loading enquanto verifica sessão
/// Redireciona para Login ou Home baseado no estado
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de pulse para o logo
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Inicializa verificação de autenticação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.unknown:
            // Verificando sessão - mostra splash premium
            return Scaffold(
              backgroundColor: const Color(0xFF000000),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animado
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD60A)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/triade_foreground.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Título
                    const Text(
                      'Tríade da Energia',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD60A),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );

          case AuthStatus.unauthenticated:
            // Não logado - vai para login
            return const LoginScreen();

          case AuthStatus.authenticated:
            // Logado - vai para home
            return const HomeScreen();
        }
      },
    );
  }
}
