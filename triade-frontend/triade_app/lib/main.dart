import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/providers/config_provider.dart';
import 'package:triade_app/providers/auth_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/screens/home_screen.dart';
import 'package:triade_app/screens/login_screen.dart';

void main() {
  runApp(const TriadeApp());
}

class TriadeApp extends StatelessWidget {
  const TriadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
      ],
      child: MaterialApp(
        title: 'Tríade do Tempo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppConstants.primaryColor,
          scaffoldBackgroundColor: AppConstants.backgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
          ),
          useMaterial3: true,
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

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Inicializa verificação de autenticação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.unknown:
            // Verificando sessão - mostra loading
            return Scaffold(
              backgroundColor: AppConstants.backgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 80,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
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
