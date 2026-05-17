import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/theme.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/activation_screen.dart';
import 'services/activation_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '投注计算器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.background,
      ),
      initialRoute: ActivationService.checkActivated() ? '/home' : '/activate',
      routes: {
        '/activate': (context) => const ActivationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
