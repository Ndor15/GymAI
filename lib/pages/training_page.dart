import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymai/services/ble_service.dart';
import 'package:gymai/services/workout_history_service.dart';
import 'package:gymai/models/workout_models.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  final BLEService ble = BLEService();
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  int lastReps = 0;
  late AnimationController pulseController;

  // Rest timer
  DateTime? lastSetTime;
  Timer? restTimer;
  int restSeconds = 0;

  // Recent sessions
  List<WorkoutSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..value = 0.0;

    // Listen for sets completed to start rest timer
    ble.currentSetsStream.listen((sets) {
      if (sets.isNotEmpty && lastSetTime != sets.last.timestamp) {
        _startRestTimer();
        lastSetTime = sets.last.timestamp;
      }
    });

    // Listen for session saved events
    ble.sessionSavedStream.listen((session) {
      if (mounted) {
        _loadRecentSessions(); // Refresh recent sessions
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

  Future<void> _loadRecentSessions() async {
    final sessions = await _historyService.getAllSessions();
    if (mounted) {
      setState(() {
        _recentSessions = sessions.take(3).toList();
      });
    }
  }

  void _startRestTimer() {
    restTimer?.cancel();
    restSeconds = 0;
    restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          restSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    pulseController.dispose();
    restTimer?.cancel();
    super.dispose();
  }

  Color tempoColor(String tempo) {
    if (tempo == "tempo normal") return Colors.greenAccent;
    if (tempo == "trop rapide") return Colors.orangeAccent;
    if (tempo == "trop lent") return Colors.redAccent;
    return Colors.grey;
  }

  // Exercise model with visual representation
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Développé couché',
      'icon': '🏋️',
      'color': const Color(0xFFE91E63),
      'category': 'Pectoraux'
    },
    {
      'name': 'Développé incliné',
      'icon': '💪',
      'color': const Color(0xFFE91E63),
      'category': 'Pectoraux'
    },
    {
      'name': 'Développé décliné',
      'icon': '🔻',
      'color': const Color(0xFFE91E63),
      'category': 'Pectoraux'
    },
    {
      'name': 'Curl biceps',
      'icon': '💪',
      'color': const Color(0xFF2196F3),
      'category': 'Biceps'
    },
    {
      'name': 'Curl marteau',
      'icon': '🔨',
      'color': const Color(0xFF2196F3),
      'category': 'Biceps'
    },
    {
      'name': 'Tractions',
      'icon': '⬆️',
      'color': const Color(0xFF4CAF50),
      'category': 'Dos'
    },
    {
      'name': 'Rowing',
      'icon': '🚣',
      'color': const Color(0xFF4CAF50),
      'category': 'Dos'
    },
    {
      'name': 'Squat',
      'icon': '🦵',
      'color': const Color(0xFFFF9800),
      'category': 'Jambes'
    },
    {
      'name': 'Presse à cuisses',
      'icon': '🦿',
      'color': const Color(0xFFFF9800),
      'category': 'Jambes'
    },
    {
      'name': 'Soulevé de terre',
      'icon': '⚡',
      'color': const Color(0xFF9C27B0),
      'category': 'Full body'
    },
    {
      'name': 'Extensions triceps',
      'icon': '💥',
      'color': const Color(0xFFF44336),
      'category': 'Triceps'
    },
    {
      'name': 'Dips',
      'icon': '⬇️',
      'color': const Color(0xFFF44336),
      'category': 'Triceps'
    },
    {
      'name': 'Élévations latérales',
      'icon': '🦅',
      'color': const Color(0xFF00BCD4),
      'category': 'Épaules'
    },
    {
      'name': 'Développé militaire',
      'icon': '🎖️',
      'color': const Color(0xFF00BCD4),
      'category': 'Épaules'
    },
    {
      'name': 'Crunch',
      'icon': '🔥',
      'color': const Color(0xFFFFEB3B),
      'category': 'Abdos'
    },
    {
      'name': 'Autre',
      'icon': '➕',
      'color': const Color(0xFF9E9E9E),
      'category': 'Autre'
    },
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

  // STEP 1: Choose exercise
  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C32E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Color(0xFFF5C32E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choisis ton exercice',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Sélectionne le mouvement effectué',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              // Exercise grid
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showExerciseDetailsDialog(exercise);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (exercise['color'] as Color).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon/Emoji
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: (exercise['color'] as Color).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    exercise['icon'] as String,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Name
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  exercise['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Category
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (exercise['color'] as Color).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  exercise['category'] as String,
                                  style: TextStyle(
                                    color: exercise['color'] as Color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2: Enter details
  void _showExerciseDetailsDialog(Map<String, dynamic> exercise) {
    final exerciseName = exercise['name'] as String;
    final exerciseColor = exercise['color'] as Color;
    final exerciseIcon = exercise['icon'] as String;

    String? selectedEquipment;
    final repsController = TextEditingController();
    double? selectedWeight;
    bool isKg = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with selected exercise
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [exerciseColor.withOpacity(0.3), exerciseColor.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: exerciseColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                exerciseIcon,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exerciseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                                const Text(
                                  'Entre les détails de ta série',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reps
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5C32E).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.repeat,
                                  color: Color(0xFFF5C32E),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Répétitions *',
                                style: TextStyle(
                                  color: Color(0xFFF5C32E),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: repsController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ex: 12',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              prefixIcon: const Icon(Icons.fitness_center, color: Color(0xFFF5C32E)),
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
                          const SizedBox(height: 24),

                          // Weight
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: exerciseColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.monitor_weight,
                                  color: exerciseColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Poids',
                                style: TextStyle(
                                  color: exerciseColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedWeight != null
                                    ? exerciseColor
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
                                    'Sélectionner ${isKg ? "kg" : "lbs"} (optionnel)',
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                ),
                                dropdownColor: const Color(0xFF1A1A1A),
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(Icons.arrow_drop_down, color: exerciseColor),
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
                          const SizedBox(height: 24),

                          // Equipment
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.build_circle_outlined,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Équipement',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedEquipment != null
                                    ? Colors.white.withOpacity(0.3)
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
                                    'Sélectionner (optionnel)',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                dropdownColor: const Color(0xFF1A1A1A),
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.arrow_drop_down, color: Colors.white54),
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
                          const SizedBox(height: 24),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5C32E),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                final reps = int.tryParse(repsController.text.trim());

                                if (reps == null || reps <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Entre un nombre de répétitions valide'),
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
                                  exercise: exerciseName,
                                  reps: reps,
                                  weight: weightInKg,
                                  equipment: selectedEquipment,
                                );

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Text(exerciseIcon, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '$exerciseName ajouté: $reps reps',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF2E7D32),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ajouter la série',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          "Training",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<bool>(
        stream: ble.workoutStateStream,
        initialData: false,
        builder: (context, workoutSnapshot) {
          final isActive = workoutSnapshot.data ?? false;

          if (!isActive) {
            return _buildInactiveView();
          }

          return _buildActiveWorkoutView();
        },
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

  Widget _buildInactiveView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5C32E).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Prêt à commencer ?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lance ta séance d\'entraînement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => ble.startWorkout(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 48),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF5C32E).withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.black, size: 28),
                        SizedBox(width: 12),
                        Text(
                          "COMMENCER",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent sessions preview
        if (_recentSessions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: Color(0xFFF5C32E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Dernières séances',
                      style: TextStyle(
                        color: Color(0xFFF5C32E),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._recentSessions.map((session) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${session.sets.length}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.formattedDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${session.totalReps} reps • ${session.formattedDuration}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveWorkoutView() {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Session Timer + Sets Counter
        StreamBuilder<Duration>(
          stream: ble.sessionDurationStream,
          initialData: Duration.zero,
          builder: (context, timerSnapshot) {
            final duration = timerSnapshot.data ?? Duration.zero;
            final minutes = duration.inMinutes.toString().padLeft(2, '0');
            final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

            return StreamBuilder<List<dynamic>>(
              stream: ble.currentSetsStream,
              initialData: const [],
              builder: (context, setsSnapshot) {
                final totalSets = setsSnapshot.data?.length ?? 0;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5C32E).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Timer
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.black,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$minutes:$seconds",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const Text(
                              'Durée',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.black.withOpacity(0.2),
                      ),
                      // Sets
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.format_list_numbered,
                              color: Colors.black,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalSets.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'Séries',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rest Timer
                      if (restSeconds > 0) ...[
                        Container(
                          width: 1,
                          height: 60,
                          color: Colors.black.withOpacity(0.2),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.hourglass_bottom,
                                color: Colors.black,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${restSeconds}s',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Repos',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // Control Buttons
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

        const SizedBox(height: 12),

        // BLE Connection Status
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

        // Current Set in Progress
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

        // Current Sets Display (horizontal scroll)
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
                maxHeight: 110,
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
                              if (!set.isManual) ...[
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

        // Main reps display
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
                    // Reps circle
                    AnimatedBuilder(
                      animation: pulseController,
                      builder: (context, child) {
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF101010),
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

                    // Exercise detected
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

        // Advice bar
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
              Expanded(
                child: Text(
                  "Garde le contrôle sur chaque phase",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
