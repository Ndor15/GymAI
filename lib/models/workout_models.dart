class WorkoutSet {
  final String exercise; // curl_biceps, curl_marteau, bench_press, etc.
  final int reps;
  final double averageTempo; // Temps moyen par rep en secondes
  final DateTime timestamp;

  // Optional fields for manual entry
  final double? weight; // Poids en kg (optionnel)
  final String? equipment; // Machine/équipement (optionnel)
  final bool isManual; // true si ajouté manuellement

  WorkoutSet({
    required this.exercise,
    required this.reps,
    required this.averageTempo,
    required this.timestamp,
    this.weight,
    this.equipment,
    this.isManual = false,
  });

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'reps': reps,
        'averageTempo': averageTempo,
        'timestamp': timestamp.toIso8601String(),
        if (weight != null) 'weight': weight,
        if (equipment != null) 'equipment': equipment,
        'isManual': isManual,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        exercise: json['exercise'] as String,
        reps: json['reps'] as int,
        averageTempo: json['averageTempo'] as double,
        timestamp: DateTime.parse(json['timestamp'] as String),
        weight: json['weight'] as double?,
        equipment: json['equipment'] as String?,
        isManual: json['isManual'] as bool? ?? false,
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

class WorkoutPost {
  final String id; // Unique identifier
  final WorkoutSession session;
  final String? photoPath; // Local path to photo (optional)
  final String? caption; // User caption (optional)
  final DateTime publishedAt;

  WorkoutPost({
    required this.id,
    required this.session,
    this.photoPath,
    this.caption,
    required this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'session': session.toJson(),
        if (photoPath != null) 'photoPath': photoPath,
        if (caption != null) 'caption': caption,
        'publishedAt': publishedAt.toIso8601String(),
      };

  factory WorkoutPost.fromJson(Map<String, dynamic> json) => WorkoutPost(
        id: json['id'] as String,
        session: WorkoutSession.fromJson(json['session'] as Map<String, dynamic>),
        photoPath: json['photoPath'] as String?,
        caption: json['caption'] as String?,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
      );

  String get formattedPublishedTime {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inHours < 1) {
      return "Il y a ${difference.inMinutes}min";
    } else if (difference.inDays < 1) {
      return "Il y a ${difference.inHours}h";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays}j";
    } else {
      return "${publishedAt.day}/${publishedAt.month}/${publishedAt.year}";
    }
  }
}
