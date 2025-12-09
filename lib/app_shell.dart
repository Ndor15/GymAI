import 'package:flutter/material.dart';
import 'pages/training_page.dart';
import 'pages/program_page.dart';
import 'pages/history_page.dart';
import 'pages/account_page.dart';
import 'services/ble_service.dart';
import 'theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final BLEService bleService = BLEService();

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const TrainingPage(),
      ProgramPage(bleService: bleService),
      const HistoryPage(),
      const AccountPage(),
    ];
  }

  void changePage(int i) {
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, -2),
              blurRadius: 6,
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: index,
          onTap: changePage,
          selectedItemColor: AppTheme.yellow,
          unselectedItemColor: Colors.white38,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: "Training",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: "Programme",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "Historique",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Compte",
            ),
          ],
        ),
      ),
    );
  }
}
