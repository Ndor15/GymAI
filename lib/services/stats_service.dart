import '../models/workout_models.dart';

class WorkoutStats {
  final int totalSessions;
  final int totalSets;
  final int totalReps;
  final double totalVolume; // kg
  final Map<String, int> exerciseCount;
  final Map<String, double> exercisePRs; // Personal Records by exercise
  final Map<String, int> weeklyActivity; // YYYY-WW -> session count
  final List<WeeklyProgress> weeklyProgress;
  final double averageSessionDuration; // minutes
  final String favoriteExercise;
  final int currentStreak; // consecutive days with workouts
  final int longestStreak;

  WorkoutStats({
    required this.totalSessions,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.exerciseCount,
    required this.exercisePRs,
    required this.weeklyActivity,
    required this.weeklyProgress,
    required this.averageSessionDuration,
    required this.favoriteExercise,
    required this.currentStreak,
    required this.longestStreak,
  });
}

class WeeklyProgress {
  final String weekLabel; // e.g., "Sem 1"
  final int totalReps;
  final double totalVolume;
  final int sessionCount;

  WeeklyProgress({
    required this.weekLabel,
    required this.totalReps,
    required this.totalVolume,
    required this.sessionCount,
  });
}

class StatsService {
  static WorkoutStats calculateStats(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return WorkoutStats(
        totalSessions: 0,
        totalSets: 0,
        totalReps: 0,
        totalVolume: 0,
        exerciseCount: {},
        exercisePRs: {},
        weeklyActivity: {},
        weeklyProgress: [],
        averageSessionDuration: 0,
        favoriteExercise: "Aucun",
        currentStreak: 0,
        longestStreak: 0,
      );
    }

    int totalSets = 0;
    int totalReps = 0;
    double totalVolume = 0;
    Map<String, int> exerciseCount = {};
    Map<String, double> exercisePRs = {};
    Map<String, int> weeklyActivity = {};
    Map<int, List<WorkoutSession>> weeklyGroups = {};

    // Calculate basic stats
    for (var session in sessions) {
      totalSets += session.sets.length;
      totalReps += session.totalReps;

      for (var set in session.sets) {
        // Count exercises
        exerciseCount[set.exercise] = (exerciseCount[set.exercise] ?? 0) + 1;

        // Calculate volume (reps * weight)
        if (set.weight != null) {
          final volume = set.reps * set.weight!;
          totalVolume += volume;

          // Track PRs (max weight for each exercise)
          if (!exercisePRs.containsKey(set.exercise) ||
              set.weight! > exercisePRs[set.exercise]!) {
            exercisePRs[set.exercise] = set.weight!;
          }
        }
      }

      // Weekly activity (ISO week number)
      final weekKey = _getWeekKey(session.date);
      weeklyActivity[weekKey] = (weeklyActivity[weekKey] ?? 0) + 1;

      // Group by week number
      final weekNumber = _getWeekNumber(session.date);
      if (!weeklyGroups.containsKey(weekNumber)) {
        weeklyGroups[weekNumber] = [];
      }
      weeklyGroups[weekNumber]!.add(session);
    }

    // Calculate weekly progress (last 8 weeks)
    final weeklyProgress = _calculateWeeklyProgress(weeklyGroups);

    // Calculate average session duration
    final totalMinutes = sessions.fold<double>(
      0,
      (sum, s) => sum + s.duration.inMinutes,
    );
    final averageSessionDuration = totalMinutes / sessions.length;

    // Find favorite exercise
    String favoriteExercise = "Aucun";
    int maxCount = 0;
    exerciseCount.forEach((exercise, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteExercise = exercise;
      }
    });

    // Calculate streaks
    final streaks = _calculateStreaks(sessions);

    return WorkoutStats(
      totalSessions: sessions.length,
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolume: totalVolume,
      exerciseCount: exerciseCount,
      exercisePRs: exercisePRs,
      weeklyActivity: weeklyActivity,
      weeklyProgress: weeklyProgress,
      averageSessionDuration: averageSessionDuration,
      favoriteExercise: favoriteExercise,
      currentStreak: streaks['current']!,
      longestStreak: streaks['longest']!,
    );
  }

  static String _getWeekKey(DateTime date) {
    final year = date.year;
    final weekNumber = _getWeekNumber(date);
    return '$year-W${weekNumber.toString().padLeft(2, '0')}';
  }

  static int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
      DateTime(date.year, date.month, date.day)
          .difference(DateTime(date.year, 1, 1))
          .inDays
          .toString(),
    );
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  static List<WeeklyProgress> _calculateWeeklyProgress(
    Map<int, List<WorkoutSession>> weeklyGroups,
  ) {
    final sortedWeeks = weeklyGroups.keys.toList()..sort();
    final last8Weeks = sortedWeeks.length > 8
        ? sortedWeeks.sublist(sortedWeeks.length - 8)
        : sortedWeeks;

    return last8Weeks.map((weekNum) {
      final sessions = weeklyGroups[weekNum]!;
      int weekReps = 0;
      double weekVolume = 0;

      for (var session in sessions) {
        weekReps += session.totalReps;
        for (var set in session.sets) {
          if (set.weight != null) {
            weekVolume += set.reps * set.weight!;
          }
        }
      }

      return WeeklyProgress(
        weekLabel: 'S$weekNum',
        totalReps: weekReps,
        totalVolume: weekVolume,
        sessionCount: sessions.length,
      );
    }).toList();
  }

  static Map<String, int> _calculateStreaks(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Sort sessions by date (most recent first)
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Get unique workout dates (ignore time)
    final workoutDates = sortedSessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Check if there's a workout today or yesterday for current streak
    if (workoutDates.isNotEmpty) {
      final daysDiff = todayDate.difference(workoutDates.first).inDays;
      if (daysDiff <= 1) {
        currentStreak = 1;

        // Calculate consecutive days
        for (int i = 0; i < workoutDates.length - 1; i++) {
          final diff = workoutDates[i].difference(workoutDates[i + 1]).inDays;
          if (diff == 1) {
            currentStreak++;
          } else {
            break;
          }
        }
      }
    }

    // Calculate longest streak
    for (int i = 0; i < workoutDates.length - 1; i++) {
      final diff = workoutDates[i].difference(workoutDates[i + 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }
}
