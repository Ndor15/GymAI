import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gymai/services/ble_service.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  final BLEService ble = BLEService();

  int lastReps = 0;
  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();
    // Don't auto-start - wait for user to click Start Workout button

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..value = 0.0;
  }

  @override
  void dispose() {
    pulseController.dispose();
    super.dispose();
  }

  Color tempoColor(String tempo) {
    if (tempo == "tempo normal") return Colors.greenAccent;
    if (tempo == "trop rapide") return Colors.orangeAccent;
    if (tempo == "trop lent") return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Session",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Start/Stop Workout Button + Session Timer
          StreamBuilder<bool>(
            stream: ble.workoutStateStream,
            initialData: false,
            builder: (context, workoutSnapshot) {
              final isActive = workoutSnapshot.data ?? false;

              return Column(
                children: [
                  // Session Timer
                  if (isActive)
                    StreamBuilder<Duration>(
                      stream: ble.sessionDurationStream,
                      initialData: Duration.zero,
                      builder: (context, timerSnapshot) {
                        final duration = timerSnapshot.data ?? Duration.zero;
                        final minutes = duration.inMinutes.toString().padLeft(2, '0');
                        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Color(0xFFF5C32E),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "$minutes:$seconds",
                                style: const TextStyle(
                                  color: Color(0xFFF5C32E),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  if (isActive) const SizedBox(height: 16),

                  // Start/Stop Button
                  GestureDetector(
                    onTap: () {
                      if (isActive) {
                        ble.stopWorkout();
                      } else {
                        ble.startWorkout();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: isActive
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [const Color(0xFFF5C32E), const Color(0xFFFFA500)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? Colors.red : const Color(0xFFF5C32E))
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.stop : Icons.play_arrow,
                            color: Colors.black,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isActive ? "STOP WORKOUT" : "START WORKOUT",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Etat connexion / proximité
          StreamBuilder<bool>(
            stream: ble.onDetected,
            initialData: false,
            builder: (context, snapshot) {
              final connected = snapshot.data ?? false;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: connected
                      ? Colors.greenAccent.withOpacity(0.12)
                      : Colors.yellowAccent.withOpacity(0.1),
                  border: Border.all(
                    color: connected
                        ? Colors.greenAccent
                        : Colors.yellowAccent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connected ? Icons.flash_on : Icons.watch,
                      color:
                      connected ? Colors.greenAccent : Colors.yellowAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected
                          ? "Haltères détectées"
                          : "En attente des haltères",
                      style: TextStyle(
                        color: connected
                            ? Colors.greenAccent
                            : Colors.yellowAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Bloc principal: reps, tempo, exercice
          Expanded(
            child: StreamBuilder<TrainingMetrics>(
              stream: ble.metricsStream,
              builder: (context, snapshot) {
                final metrics = snapshot.data;
                final reps = metrics?.reps ?? 0;
                final tempo = metrics?.tempo ?? "en attente";
                final exercise = metrics?.exercise ?? "mouvement non reconnu";
                final conf = metrics?.confidence ?? 0;

                if (reps != lastReps && reps > 0) {
                  lastReps = reps;
                  // Only animate if not already animating
                  if (!pulseController.isAnimating) {
                    pulseController.forward(from: 0.0).then((_) {
                      pulseController.reverse();
                    });
                  }
                }

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cercle reps
                      AnimatedBuilder(
                        animation: pulseController,
                        builder: (context, child) {
                          // Map 0.0-1.0 to 0.95-1.05 with easeOutBack curve
                          final curvedValue = Curves.easeOutBack.transform(pulseController.value);
                          final scale = 0.95 + (curvedValue * 0.10);
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFFFFEB3B),
                                Color(0xFFFFC107),
                                Color(0xFFFFEB3B),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.yellowAccent.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF101010),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Reps",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reps.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Tempo chip
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: tempoColor(tempo).withOpacity(0.12),
                          border: Border.all(
                            color: tempoColor(tempo),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.speed,
                              size: 18,
                              color: tempoColor(tempo),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tempo,
                              style: TextStyle(
                                color: tempoColor(tempo),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Exercice détecté
                      Column(
                        children: [
                          Text(
                            exercise,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conf > 0
                                ? "Confiance ${conf.toStringAsFixed(2)}"
                                : "En attente de détection",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Petite barre info en bas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF080808),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Conseil",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Garde le contrôle sur chaque phase",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
