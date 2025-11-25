import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Center(
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, size: 70, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "Nils Dahan",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),

        const SizedBox(height: 30),
        const Text(
          "Statistiques",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        _statTile("Volume total", "127 500 kg"),
        _statTile("Séances", "34"),
        _statTile("Record haltère", "36 kg"),
      ],
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 17, color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
