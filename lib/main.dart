import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'pages/onboarding_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GymAIApp());
}

class GymAIApp extends StatefulWidget {
  const GymAIApp({super.key});

  @override
  State<GymAIApp> createState() => _GymAIAppState();
}

class _GymAIAppState extends State<GymAIApp> {
  bool started = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: started
          ? const AppShell()
          : OnboardingPage(onStart: () {
        setState(() => started = true);
      }),
    );
  }
}
