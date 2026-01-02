import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/providers/config_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/screens/home_screen.dart'; // ← NOVO

void main() {
  runApp(const TriadeApp());
}

class TriadeApp extends StatelessWidget {
  const TriadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        home: const HomeScreen(), // ← MUDANÇA AQUI
      ),
    );
  }
}
