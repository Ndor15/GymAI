import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = [
      {"date": "Aujourd’hui", "duration": "32 min", "volume": "5 400 kg"},
      {"date": "Hier", "duration": "28 min", "volume": "4 800 kg"},
      {"date": "Samedi", "duration": "41 min", "volume": "7 200 kg"},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Historique des séances",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),

        ...sessions.map((s) => _buildSessionCard(s)),
      ],
    );
  }

  Widget _buildSessionCard(Map s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s["date"],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Durée : ${s["duration"]}",
                  style: const TextStyle(color: Colors.white70)),
              Text("Volume : ${s["volume"]}",
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}
