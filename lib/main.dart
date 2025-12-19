import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_shell.dart';
import 'pages/onboarding_page.dart';
import 'pages/auth_page.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GymAIApp());
}

class GymAIApp extends StatefulWidget {
  const GymAIApp({super.key});

  @override
  State<GymAIApp> createState() => _GymAIAppState();
}

class _GymAIAppState extends State<GymAIApp> {
  final AuthService _authService = AuthService();
  bool started = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.yellow),
              ),
            );
          }

          // User is authenticated
          if (snapshot.hasData) {
            return started
                ? const AppShell()
                : OnboardingPage(onStart: () {
                    setState(() => started = true);
                  });
          }

          // User is not authenticated
          return const AuthPage();
        },
      ),
    );
  }
}
