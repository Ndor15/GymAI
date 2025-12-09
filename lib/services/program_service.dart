import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_models.dart';

class ProgramService {
  static const String _activeProgramKey = 'active_program';

  // Predefined workout programs
  static final List<WorkoutProgram> _programs = [
    // BEGINNER - MUSCLE
    WorkoutProgram(
      id: 'beginner_muscle',
      name: 'Prise de Masse Débutant',
      description: 'Programme 3 jours pour développer la masse musculaire',
      goal: 'muscle',
      level: 'beginner',
      daysPerWeek: 3,
      days: [
        WorkoutDay(
          name: 'Jour 1 - Full Body A',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 3,
              reps: 12,
              restSeconds: 90,
              notes: 'Contrôle la descente',
            ),
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 90,
              notes: 'Garde le dos droit',
            ),
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 3,
              reps: 12,
              restSeconds: 120,
              notes: 'Descend jusqu\'aux parallèles',
            ),
            ProgramExercise(
              name: 'Curl marteau',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Jour 2 - Full Body B',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé militaire',
              icon: '🏋️',
              sets: 3,
              reps: 12,
              restSeconds: 90,
              notes: 'Serre les abdos',
            ),
            ProgramExercise(
              name: 'Soulevé de terre',
              icon: '💪',
              sets: 3,
              reps: 10,
              restSeconds: 120,
              notes: 'Dos bien droit',
            ),
            ProgramExercise(
              name: 'Fentes',
              icon: '🦵',
              sets: 3,
              reps: 10,
              restSeconds: 90,
              notes: 'Alterner les jambes',
            ),
            ProgramExercise(
              name: 'Extension triceps',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Jour 3 - Full Body C',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé incliné',
              icon: '🏋️',
              sets: 3,
              reps: 12,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Traction',
              icon: '💪',
              sets: 3,
              reps: 8,
              restSeconds: 90,
              notes: 'Assistées si nécessaire',
            ),
            ProgramExercise(
              name: 'Presse à cuisses',
              icon: '🦵',
              sets: 3,
              reps: 15,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Curl biceps',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
          ],
        ),
      ],
    ),

    // INTERMEDIATE - MUSCLE
    WorkoutProgram(
      id: 'intermediate_muscle',
      name: 'Push Pull Legs',
      description: 'Programme 4-5 jours pour maximiser la croissance musculaire',
      goal: 'muscle',
      level: 'intermediate',
      daysPerWeek: 4,
      days: [
        WorkoutDay(
          name: 'Push - Poitrine/Épaules/Triceps',
          focus: 'Push',
          exercises: [
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 4,
              reps: 10,
              restSeconds: 120,
            ),
            ProgramExercise(
              name: 'Développé incliné',
              icon: '🏋️',
              sets: 3,
              reps: 12,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Développé militaire',
              icon: '🏋️',
              sets: 4,
              reps: 10,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Élévations latérales',
              icon: '💪',
              sets: 3,
              reps: 15,
              restSeconds: 60,
            ),
            ProgramExercise(
              name: 'Extension triceps',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Pull - Dos/Biceps',
          focus: 'Pull',
          exercises: [
            ProgramExercise(
              name: 'Soulevé de terre',
              icon: '💪',
              sets: 4,
              reps: 8,
              restSeconds: 150,
              notes: 'Exercice roi pour le dos',
            ),
            ProgramExercise(
              name: 'Traction',
              icon: '💪',
              sets: 4,
              reps: 10,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 4,
              reps: 10,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Curl biceps',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
            ProgramExercise(
              name: 'Curl marteau',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Legs - Jambes',
          focus: 'Legs',
          exercises: [
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 4,
              reps: 10,
              restSeconds: 150,
              notes: 'Exercice principal',
            ),
            ProgramExercise(
              name: 'Presse à cuisses',
              icon: '🦵',
              sets: 3,
              reps: 12,
              restSeconds: 120,
            ),
            ProgramExercise(
              name: 'Fentes',
              icon: '🦵',
              sets: 3,
              reps: 12,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Leg curl',
              icon: '🦵',
              sets: 3,
              reps: 12,
              restSeconds: 60,
            ),
            ProgramExercise(
              name: 'Mollets',
              icon: '🦵',
              sets: 4,
              reps: 15,
              restSeconds: 45,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Upper - Haut du corps',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 3,
              reps: 12,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Développé militaire',
              icon: '🏋️',
              sets: 3,
              reps: 10,
              restSeconds: 90,
            ),
            ProgramExercise(
              name: 'Traction',
              icon: '💪',
              sets: 3,
              reps: 10,
              restSeconds: 90,
            ),
          ],
        ),
      ],
    ),

    // BEGINNER - STRENGTH
    WorkoutProgram(
      id: 'beginner_strength',
      name: 'Force Débutant',
      description: 'Programme 3 jours pour développer la force',
      goal: 'strength',
      level: 'beginner',
      daysPerWeek: 3,
      days: [
        WorkoutDay(
          name: 'Jour A - Squat',
          focus: 'Legs',
          exercises: [
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 5,
              reps: 5,
              restSeconds: 180,
              notes: 'Charge lourde',
            ),
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 5,
              reps: 5,
              restSeconds: 180,
            ),
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 5,
              reps: 5,
              restSeconds: 120,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Jour B - Soulevé de terre',
          focus: 'Pull',
          exercises: [
            ProgramExercise(
              name: 'Soulevé de terre',
              icon: '💪',
              sets: 5,
              reps: 5,
              restSeconds: 180,
              notes: 'Exercice roi',
            ),
            ProgramExercise(
              name: 'Développé militaire',
              icon: '🏋️',
              sets: 5,
              reps: 5,
              restSeconds: 150,
            ),
            ProgramExercise(
              name: 'Traction',
              icon: '💪',
              sets: 5,
              reps: 5,
              restSeconds: 120,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Jour C - Squat léger',
          focus: 'Legs',
          exercises: [
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 3,
              reps: 8,
              restSeconds: 120,
              notes: 'Charge modérée',
            ),
            ProgramExercise(
              name: 'Développé incliné',
              icon: '🏋️',
              sets: 5,
              reps: 5,
              restSeconds: 150,
            ),
            ProgramExercise(
              name: 'Rowing haltères',
              icon: '💪',
              sets: 5,
              reps: 8,
              restSeconds: 90,
            ),
          ],
        ),
      ],
    ),

    // BEGINNER - ENDURANCE
    WorkoutProgram(
      id: 'beginner_endurance',
      name: 'Endurance Musculaire',
      description: 'Programme 4 jours pour développer l\'endurance',
      goal: 'endurance',
      level: 'beginner',
      daysPerWeek: 4,
      days: [
        WorkoutDay(
          name: 'Circuit Full Body A',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 3,
              reps: 20,
              restSeconds: 45,
              notes: 'Charge légère',
            ),
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 3,
              reps: 20,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 3,
              reps: 20,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Fentes',
              icon: '🦵',
              sets: 3,
              reps: 15,
              restSeconds: 45,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Circuit Full Body B',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé militaire',
              icon: '🏋️',
              sets: 3,
              reps: 20,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Soulevé de terre',
              icon: '💪',
              sets: 3,
              reps: 15,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Curl biceps',
              icon: '💪',
              sets: 3,
              reps: 20,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Extension triceps',
              icon: '💪',
              sets: 3,
              reps: 20,
              restSeconds: 30,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Circuit Upper',
          focus: 'Push',
          exercises: [
            ProgramExercise(
              name: 'Développé incliné',
              icon: '🏋️',
              sets: 4,
              reps: 20,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Traction',
              icon: '💪',
              sets: 4,
              reps: 12,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Élévations latérales',
              icon: '💪',
              sets: 3,
              reps: 20,
              restSeconds: 30,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Circuit Lower',
          focus: 'Legs',
          exercises: [
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 4,
              reps: 20,
              restSeconds: 60,
            ),
            ProgramExercise(
              name: 'Fentes',
              icon: '🦵',
              sets: 3,
              reps: 20,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Mollets',
              icon: '🦵',
              sets: 4,
              reps: 25,
              restSeconds: 30,
            ),
          ],
        ),
      ],
    ),

    // BEGINNER - WEIGHT LOSS
    WorkoutProgram(
      id: 'beginner_weightloss',
      name: 'Perte de Poids',
      description: 'Programme 5 jours haute intensité pour brûler les graisses',
      goal: 'weight_loss',
      level: 'beginner',
      daysPerWeek: 5,
      days: [
        WorkoutDay(
          name: 'HIIT Full Body',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 4,
              reps: 15,
              restSeconds: 30,
              notes: 'Tempo rapide',
            ),
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 4,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Fentes',
              icon: '🦵',
              sets: 3,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 3,
              reps: 15,
              restSeconds: 30,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Circuit Upper',
          focus: 'Push',
          exercises: [
            ProgramExercise(
              name: 'Développé militaire',
              icon: '🏋️',
              sets: 4,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Curl biceps',
              icon: '💪',
              sets: 3,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Extension triceps',
              icon: '💪',
              sets: 3,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Élévations latérales',
              icon: '💪',
              sets: 3,
              reps: 20,
              restSeconds: 20,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Circuit Lower',
          focus: 'Legs',
          exercises: [
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 4,
              reps: 20,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Soulevé de terre',
              icon: '💪',
              sets: 3,
              reps: 12,
              restSeconds: 45,
            ),
            ProgramExercise(
              name: 'Fentes',
              icon: '🦵',
              sets: 4,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Mollets',
              icon: '🦵',
              sets: 3,
              reps: 25,
              restSeconds: 20,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Full Body Express',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Développé couché',
              icon: '🏋️',
              sets: 3,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Traction',
              icon: '💪',
              sets: 3,
              reps: 10,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Presse à cuisses',
              icon: '🦵',
              sets: 3,
              reps: 20,
              restSeconds: 30,
            ),
          ],
        ),
        WorkoutDay(
          name: 'Circuit Total Body',
          focus: 'Full Body',
          exercises: [
            ProgramExercise(
              name: 'Rowing barre',
              icon: '💪',
              sets: 4,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Développé incliné',
              icon: '🏋️',
              sets: 3,
              reps: 15,
              restSeconds: 30,
            ),
            ProgramExercise(
              name: 'Squat',
              icon: '🦵',
              sets: 4,
              reps: 15,
              restSeconds: 30,
            ),
          ],
        ),
      ],
    ),
  ];

  // Get recommended programs based on user profile
  static List<WorkoutProgram> recommendPrograms(UserProfile profile) {
    return _programs.where((program) {
      return program.goal == profile.goal &&
          program.level == profile.level &&
          program.daysPerWeek <= profile.daysPerWeek;
    }).toList();
  }

  // Get all available programs
  static List<WorkoutProgram> getAllPrograms() {
    return _programs;
  }

  // Get program by ID
  static WorkoutProgram? getProgramById(String id) {
    try {
      return _programs.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save active program to storage
  static Future<void> saveActiveProgram(ActiveProgram program) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProgramKey, jsonEncode(program.toJson()));
  }

  // Load active program from storage
  static Future<ActiveProgram?> loadActiveProgram() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final programJson = prefs.getString(_activeProgramKey);
      if (programJson == null) return null;

      final data = jsonDecode(programJson) as Map<String, dynamic>;
      return ActiveProgram.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // Clear active program
  static Future<void> clearActiveProgram() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeProgramKey);
  }

  // Advance to next set
  static ActiveProgram nextSet(ActiveProgram current) {
    final currentExercise = current.currentExercise;

    if (current.currentSet < currentExercise.sets) {
      // Still have sets remaining for this exercise
      return current.copyWith(currentSet: current.currentSet + 1);
    } else {
      // Move to next exercise
      return nextExercise(current);
    }
  }

  // Advance to next exercise
  static ActiveProgram nextExercise(ActiveProgram current) {
    final currentDay = current.currentDay;

    if (current.currentExerciseIndex < currentDay.exercises.length - 1) {
      // Move to next exercise in current day
      return current.copyWith(
        currentExerciseIndex: current.currentExerciseIndex + 1,
        currentSet: 1, // Reset to first set
      );
    } else {
      // Day is completed, move to next day
      return nextDay(current);
    }
  }

  // Advance to next day
  static ActiveProgram nextDay(ActiveProgram current) {
    if (current.currentDayIndex < current.program.days.length - 1) {
      // Move to next day
      return current.copyWith(
        currentDayIndex: current.currentDayIndex + 1,
        currentExerciseIndex: 0,
        currentSet: 1,
      );
    } else {
      // Program completed, cycle back to first day
      return current.copyWith(
        currentDayIndex: 0,
        currentExerciseIndex: 0,
        currentSet: 1,
      );
    }
  }

  // Check if current set is completed (based on target reps)
  static bool isSetCompleted(ActiveProgram program, int detectedReps) {
    final targetReps = program.currentExercise.reps;
    // Consider set complete if within 80% of target (allows some flexibility)
    return detectedReps >= (targetReps * 0.8).round();
  }

  // Get progress percentage for current day
  static double getDayProgress(ActiveProgram program) {
    final currentDay = program.currentDay;
    final totalExercises = currentDay.exercises.length;

    if (totalExercises == 0) return 0;

    // Calculate based on completed exercises + current exercise progress
    final completedExercises = program.currentExerciseIndex;
    final currentExercise = program.currentExercise;
    final currentExerciseProgress =
        (program.currentSet - 1) / currentExercise.sets;

    final totalProgress =
        (completedExercises + currentExerciseProgress) / totalExercises;

    return totalProgress.clamp(0.0, 1.0);
  }

  // Get total progress percentage for program
  static double getProgramProgress(ActiveProgram program) {
    final totalDays = program.program.days.length;
    if (totalDays == 0) return 0;

    final completedDays = program.currentDayIndex;
    final currentDayProgress = getDayProgress(program);

    final totalProgress = (completedDays + currentDayProgress) / totalDays;
    return totalProgress.clamp(0.0, 1.0);
  }
}
