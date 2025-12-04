class WorkoutSet {
  final String exercise; // curl_biceps, curl_marteau
  final int reps;
  final double averageTempo; // Temps moyen par rep en secondes
  final DateTime timestamp;

  WorkoutSet({
    required this.exercise,
    required this.reps,
    required this.averageTempo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'reps': reps,
        'averageTempo': averageTempo,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        exercise: json['exercise'] as String,
        reps: json['reps'] as int,
        averageTempo: json['averageTempo'] as double,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String get displayExercise {
    switch (exercise) {
      case 'curl_biceps':
        return 'Curl Biceps';
      case 'curl_marteau':
        return 'Curl Marteau';
      default:
        return exercise;
    }
  }

  String get formattedTempo => '${averageTempo.toStringAsFixed(1)}s/rep';
}

class WorkoutSession {
  final DateTime date;
  final Duration duration;
  final List<WorkoutSet> sets;

  WorkoutSession({
    required this.date,
    required this.duration,
    required this.sets,
  });

  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'duration': duration.inSeconds,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        date: DateTime.parse(json['date'] as String),
        duration: Duration(seconds: json['duration'] as int),
        sets: (json['sets'] as List)
            .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}min ${seconds}s';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return "Aujourd'hui";
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return "Hier";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
