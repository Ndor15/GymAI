import 'package:flutter/material.dart';
import '../models/program_models.dart';
import '../services/program_service.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';

class ProgramPage extends StatefulWidget {
  final BLEService bleService;

  const ProgramPage({super.key, required this.bleService});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  // Quiz state
  int _currentQuizStep = 0;
  String? _selectedGoal;
  String? _selectedLevel;
  int? _selectedDays;
  List<String> _selectedEquipment = [];

  // Programs state
  List<WorkoutProgram> _recommendedPrograms = [];
  bool _showQuiz = true;

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'muscle',
      'name': 'Prise de masse',
      'icon': '💪',
      'description': 'Développer la masse musculaire',
      'color': const Color(0xFFE91E63),
    },
    {
      'id': 'strength',
      'name': 'Force',
      'icon': '🏋️',
      'description': 'Augmenter la force maximale',
      'color': const Color(0xFFFF5722),
    },
    {
      'id': 'endurance',
      'name': 'Endurance',
      'icon': '🏃',
      'description': 'Améliorer l\'endurance musculaire',
      'color': const Color(0xFF2196F3),
    },
    {
      'id': 'weight_loss',
      'name': 'Perte de poids',
      'icon': '🔥',
      'description': 'Brûler les graisses',
      'color': const Color(0xFFF5C32E),
    },
  ];

  final List<Map<String, dynamic>> _levels = [
    {
      'id': 'beginner',
      'name': 'Débutant',
      'icon': '🌱',
      'description': 'Moins de 6 mois d\'expérience',
    },
    {
      'id': 'intermediate',
      'name': 'Intermédiaire',
      'icon': '💪',
      'description': '6 mois - 2 ans d\'expérience',
    },
    {
      'id': 'advanced',
      'name': 'Avancé',
      'icon': '🏆',
      'description': 'Plus de 2 ans d\'expérience',
    },
  ];

  final List<Map<String, dynamic>> _daysOptions = [
    {'days': 3, 'label': '3 jours/semaine', 'icon': '📅'},
    {'days': 4, 'label': '4 jours/semaine', 'icon': '📆'},
    {'days': 5, 'label': '5 jours/semaine', 'icon': '🗓️'},
    {'days': 6, 'label': '6 jours/semaine', 'icon': '📋'},
  ];

  final List<Map<String, dynamic>> _equipmentOptions = [
    {'id': 'dumbbell', 'name': 'Haltères', 'icon': '🏋️'},
    {'id': 'barbell', 'name': 'Barre', 'icon': '💪'},
    {'id': 'machine', 'name': 'Machines', 'icon': '⚙️'},
    {'id': 'bodyweight', 'name': 'Poids du corps', 'icon': '🤸'},
  ];

  void _nextQuizStep() {
    if (_currentQuizStep < 3) {
      setState(() {
        _currentQuizStep++;
      });
    } else {
      _completeQuiz();
    }
  }

  void _previousQuizStep() {
    if (_currentQuizStep > 0) {
      setState(() {
        _currentQuizStep--;
      });
    }
  }

  void _completeQuiz() {
    if (_selectedGoal == null ||
        _selectedLevel == null ||
        _selectedDays == null ||
        _selectedEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez compléter toutes les étapes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profile = UserProfile(
      goal: _selectedGoal!,
      level: _selectedLevel!,
      daysPerWeek: _selectedDays!,
      availableEquipment: _selectedEquipment,
    );

    setState(() {
      _recommendedPrograms = ProgramService.recommendPrograms(profile);
      _showQuiz = false;
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuizStep = 0;
      _selectedGoal = null;
      _selectedLevel = null;
      _selectedDays = null;
      _selectedEquipment = [];
      _recommendedPrograms = [];
      _showQuiz = true;
    });
  }

  Future<void> _startProgram(WorkoutProgram program) async {
    final activeProgram = ActiveProgram(
      program: program,
      currentDayIndex: 0,
      currentExerciseIndex: 0,
      currentSet: 1,
      startDate: DateTime.now(),
    );

    await ProgramService.saveActiveProgram(activeProgram);

    if (!mounted) return;

    // Navigate to training page (it will detect the active program)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Programme "${program.name}" démarré !'),
        backgroundColor: AppTheme.yellow,
        duration: const Duration(seconds: 2),
      ),
    );

    // Switch to training tab (index 1)
    DefaultTabController.of(context).animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _showQuiz ? _buildQuizView() : _buildProgramsView(),
    );
  }

  Widget _buildQuizView() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.background,
            child: Column(
              children: [
                const Row(
                  children: [
                    Text(
                      '📋',
                      style: TextStyle(fontSize: 32),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trouve ton programme',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Réponds à quelques questions',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                Row(
                  children: List.generate(4, (index) {
                    final isCompleted = index < _currentQuizStep;
                    final isCurrent = index == _currentQuizStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index < 3 ? 8 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppTheme.yellow
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Quiz content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildQuizStep(),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentQuizStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuizStep,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.yellow),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Retour',
                        style: TextStyle(color: AppTheme.yellow),
                      ),
                    ),
                  ),
                if (_currentQuizStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _canProceed() ? _nextQuizStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    child: Text(
                      _currentQuizStep < 3 ? 'Suivant' : 'Voir les programmes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentQuizStep) {
      case 0:
        return _selectedGoal != null;
      case 1:
        return _selectedLevel != null;
      case 2:
        return _selectedDays != null;
      case 3:
        return _selectedEquipment.isNotEmpty;
      default:
        return false;
    }
  }

  Widget _buildQuizStep() {
    switch (_currentQuizStep) {
      case 0:
        return _buildGoalSelection();
      case 1:
        return _buildLevelSelection();
      case 2:
        return _buildDaysSelection();
      case 3:
        return _buildEquipmentSelection();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGoalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quel est ton objectif principal ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...(_goals.map((goal) {
          final isSelected = _selectedGoal == goal['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGoal = goal['id']),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isSelected ? 0.08 : 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? goal['color']
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: goal['color'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          goal['icon'],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            goal['description'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: goal['color'],
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildLevelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quel est ton niveau ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...(_levels.map((level) {
          final isSelected = _selectedLevel == level['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedLevel = level['id']),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isSelected ? 0.08 : 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.yellow
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      level['icon'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            level['description'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.yellow,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildDaysSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Combien de jours peux-tu t\'entraîner ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...(_daysOptions.map((option) {
          final isSelected = _selectedDays == option['days'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDays = option['days']),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isSelected ? 0.08 : 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.yellow
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      option['icon'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option['label'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.yellow,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildEquipmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quel équipement as-tu ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionne tous ceux qui s\'appliquent',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ...(_equipmentOptions.map((equipment) {
          final isSelected = _selectedEquipment.contains(equipment['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedEquipment.remove(equipment['id']);
                  } else {
                    _selectedEquipment.add(equipment['id']);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isSelected ? 0.08 : 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.yellow
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      equipment['icon'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        equipment['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppTheme.yellow : Colors.white54,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildProgramsView() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.background,
            child: Row(
              children: [
                IconButton(
                  onPressed: _resetQuiz,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Programmes recommandés',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Basés sur ton profil',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Programs list
          Expanded(
            child: _recommendedPrograms.isEmpty
                ? _buildNoPrograms()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _recommendedPrograms.length,
                    itemBuilder: (context, index) {
                      final program = _recommendedPrograms[index];
                      return _buildProgramCard(program);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPrograms() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '😕',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun programme trouvé',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essaye de changer tes critères',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Refaire le quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(WorkoutProgram program) {
    final goalData = _goals.firstWhere((g) => g['id'] == program.goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goalData['color'].withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  goalData['icon'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        program.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildProgramStat(
                      '📅',
                      '${program.daysPerWeek} jours/sem',
                    ),
                    const SizedBox(width: 20),
                    _buildProgramStat(
                      '🎯',
                      '${program.days.length} séances',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Séances du programme :',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...program.days.asMap().entries.map((entry) {
                  final day = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: AppTheme.yellow,
                                fontWeight: FontWeight.bold,
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
                                day.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${day.exercises.length} exercices · ${day.totalSets} sets',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startProgram(program),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Commencer ce programme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildProgramStat(String icon, String label) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
