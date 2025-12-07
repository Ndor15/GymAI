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

    // Listen for session saved events
    ble.sessionSavedStream.listen((session) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Session enregistrée !',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${session.sets.length} séries • ${session.totalReps} reps',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
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

  // Predefined options for dropdowns
  final List<String> _exercises = [
    'Développé couché',
    'Développé incliné',
    'Développé décliné',
    'Curl biceps',
    'Curl marteau',
    'Tractions',
    'Rowing',
    'Squat',
    'Presse à cuisses',
    'Soulevé de terre',
    'Extensions triceps',
    'Dips',
    'Élévations latérales',
    'Autre',
  ];

  final List<String> _equipment = [
    'Barre libre',
    'Haltères',
    'Smith machine',
    'Poulie',
    'Machine guidée',
    'Poids du corps',
    'Autre',
  ];

  final List<double> _commonWeights = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50,
    55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
    110, 120, 130, 140, 150
  ];

  void _showManualEntryDialog() {
    String? selectedExercise;
    String? selectedEquipment;
    final repsController = TextEditingController();
    double? selectedWeight;
    bool isKg = true; // true = kg, false = lbs

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0A0A0A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C32E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: Color(0xFFF5C32E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nouvel exercice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercice dropdown
                    const Text(
                      'Exercice *',
                      style: TextStyle(
                        color: Color(0xFFF5C32E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedExercise != null
                              ? const Color(0xFFF5C32E)
                              : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedExercise,
                          isExpanded: true,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Sélectionner un exercice',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          dropdownColor: const Color(0xFF1A1A1A),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_drop_down, color: Color(0xFFF5C32E)),
                          ),
                          items: _exercises.map((exercise) {
                            return DropdownMenuItem(
                              value: exercise,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  exercise,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedExercise = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reps
                    const Text(
                      'Répétitions *',
                      style: TextStyle(
                        color: Color(0xFFF5C32E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Ex: 12',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFF5C32E), width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weight with kg/lbs toggle
                    Row(
                      children: [
                        const Text(
                          'Poids',
                          style: TextStyle(
                            color: Color(0xFFF5C32E),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => isKg = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isKg ? const Color(0xFFF5C32E) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'KG',
                                    style: TextStyle(
                                      color: isKg ? Colors.black : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => isKg = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: !isKg ? const Color(0xFFF5C32E) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LBS',
                                    style: TextStyle(
                                      color: !isKg ? Colors.black : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedWeight != null
                              ? const Color(0xFFF5C32E)
                              : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: selectedWeight,
                          isExpanded: true,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Sélectionner ${isKg ? "kg" : "lbs"}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                          dropdownColor: const Color(0xFF1A1A1A),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_drop_down, color: Color(0xFFF5C32E)),
                          ),
                          items: _commonWeights.map((weight) {
                            final displayWeight = isKg ? weight : (weight * 2.20462).round();
                            return DropdownMenuItem(
                              value: isKg ? weight : weight * 2.20462,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$displayWeight ${isKg ? "kg" : "lbs"}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedWeight = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Equipment dropdown
                    const Text(
                      'Équipement',
                      style: TextStyle(
                        color: Color(0xFFF5C32E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedEquipment != null
                              ? const Color(0xFFF5C32E)
                              : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedEquipment,
                          isExpanded: true,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Sélectionner l\'équipement',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          dropdownColor: const Color(0xFF1A1A1A),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_drop_down, color: Color(0xFFF5C32E)),
                          ),
                          items: _equipment.map((equip) {
                            return DropdownMenuItem(
                              value: equip,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  equip,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedEquipment = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5C32E),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final reps = int.tryParse(repsController.text.trim());

                  if (selectedExercise == null || reps == null || reps <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exercice et reps sont requis'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Convert lbs to kg if needed
                  final weightInKg = selectedWeight != null && !isKg
                      ? selectedWeight! / 2.20462
                      : selectedWeight;

                  ble.addManualSet(
                    exercise: selectedExercise!,
                    reps: reps,
                    weight: weightInKg,
                    equipment: selectedEquipment,
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $selectedExercise ajouté: $reps reps'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 6),
                    Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
          const SizedBox(height: 12),

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
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$minutes:$seconds",
                                style: const TextStyle(
                                  color: Color(0xFFF5C32E),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  if (isActive) const SizedBox(height: 12),

                  // Workout Control Buttons
                  if (!isActive)
                    // START button
                    GestureDetector(
                      onTap: () => ble.startWorkout(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF5C32E).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.black, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "START WORKOUT",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // PAUSE/RESUME + STOP buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PAUSE/RESUME button
                        GestureDetector(
                          onTap: () {
                            if (ble.isWorkoutPaused) {
                              ble.resumeWorkout();
                            } else {
                              ble.pauseWorkout();
                            }
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: ble.isWorkoutPaused
                                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                    : [const Color(0xFFFFA726), const Color(0xFFFF9800)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (ble.isWorkoutPaused ? Colors.green : Colors.orange)
                                      .withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ble.isWorkoutPaused ? Icons.play_arrow : Icons.pause,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ble.isWorkoutPaused ? "RESUME" : "PAUSE",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // STOP button
                        GestureDetector(
                          onTap: () => ble.stopWorkout(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade600],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stop, color: Colors.black, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "STOP",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

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

          const SizedBox(height: 12),

          // Current Set in Progress (not finalized yet)
          StreamBuilder<int>(
            stream: ble.currentSetRepsStream,
            initialData: 0,
            builder: (context, currentSetSnapshot) {
              final currentSetReps = currentSetSnapshot.data ?? 0;

              if (currentSetReps == 0) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C32E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF5C32E),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Color(0xFFF5C32E),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Série en cours: $currentSetReps reps',
                      style: const TextStyle(
                        color: Color(0xFFF5C32E),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '(30s pour valider)',
                      style: TextStyle(
                        color: Color(0xFFF5C32E),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Current Sets Display
          StreamBuilder<List<dynamic>>(
            stream: ble.currentSetsStream,
            initialData: const [],
            builder: (context, setsSnapshot) {
              final sets = setsSnapshot.data ?? [];

              if (sets.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(
                  maxHeight: 110, // Limite la hauteur pour éviter overflow
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Color(0xFFF5C32E),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Séries complétées: ${sets.length}',
                          style: const TextStyle(
                            color: Color(0xFFF5C32E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final set = sets[index];
                          return Container(
                            width: 140,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101010),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  set.displayExercise,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.repeat,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${set.reps} reps',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.speed,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      set.formattedTempo,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
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
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

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
                          width: 170,
                          height: 170,
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
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reps.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 12),

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
      floatingActionButton: StreamBuilder<bool>(
        stream: ble.workoutStateStream,
        initialData: false,
        builder: (context, snapshot) {
          final isActive = snapshot.data ?? false;
          if (!isActive) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: _showManualEntryDialog,
            backgroundColor: const Color(0xFFF5C32E),
            foregroundColor: Colors.black,
            elevation: 8,
            icon: const Icon(Icons.add_circle, size: 24),
            label: const Text(
              'Exercice',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
