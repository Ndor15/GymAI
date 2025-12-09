// Models for workout programs

class UserProfile {
  final String goal; // 'muscle', 'strength', 'endurance', 'weight_loss'
  final String level; // 'beginner', 'intermediate', 'advanced'
  final int daysPerWeek;
  final List<String> availableEquipment;

  UserProfile({
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.availableEquipment,
  });

  Map<String, dynamic> toJson() => {
    'goal': goal,
    'level': level,
    'daysPerWeek': daysPerWeek,
    'availableEquipment': availableEquipment,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    goal: json['goal'] as String,
    level: json['level'] as String,
    daysPerWeek: json['daysPerWeek'] as int,
    availableEquipment: List<String>.from(json['availableEquipment'] as List),
  );
}

class ProgramExercise {
  final String name;
  final String icon;
  final int sets;
  final int reps;
  final int restSeconds;
  final String? notes;

  ProgramExercise({
    required this.name,
    required this.icon,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'sets': sets,
    'reps': reps,
    'restSeconds': restSeconds,
    if (notes != null) 'notes': notes,
  };

  factory ProgramExercise.fromJson(Map<String, dynamic> json) => ProgramExercise(
    name: json['name'] as String,
    icon: json['icon'] as String,
    sets: json['sets'] as int,
    reps: json['reps'] as int,
    restSeconds: json['restSeconds'] as int,
    notes: json['notes'] as String?,
  );
}

class WorkoutDay {
  final String name;
  final String focus; // e.g., "Push", "Pull", "Legs", "Full Body"
  final List<ProgramExercise> exercises;

  WorkoutDay({
    required this.name,
    required this.focus,
    required this.exercises,
  });

  int get totalExercises => exercises.length;
  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets);

  Map<String, dynamic> toJson() => {
    'name': name,
    'focus': focus,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
    name: json['name'] as String,
    focus: json['focus'] as String,
    exercises: (json['exercises'] as List)
        .map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final String goal;
  final String level;
  final int daysPerWeek;
  final List<WorkoutDay> days;

  WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'goal': goal,
    'level': level,
    'daysPerWeek': daysPerWeek,
    'days': days.map((d) => d.toJson()).toList(),
  };

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => WorkoutProgram(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    goal: json['goal'] as String,
    level: json['level'] as String,
    daysPerWeek: json['daysPerWeek'] as int,
    days: (json['days'] as List)
        .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
        .toList(),
  );
}

// Active program tracking
class ActiveProgram {
  final WorkoutProgram program;
  final int currentDayIndex;
  final int currentExerciseIndex;
  final int currentSet;
  final DateTime startDate;

  ActiveProgram({
    required this.program,
    required this.currentDayIndex,
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.startDate,
  });

  ProgramExercise get currentExercise =>
      program.days[currentDayIndex].exercises[currentExerciseIndex];

  WorkoutDay get currentDay => program.days[currentDayIndex];

  bool get isCompleted =>
      currentDayIndex >= program.days.length;

  bool get isDayCompleted =>
      currentExerciseIndex >= currentDay.exercises.length;

  Map<String, dynamic> toJson() => {
    'program': program.toJson(),
    'currentDayIndex': currentDayIndex,
    'currentExerciseIndex': currentExerciseIndex,
    'currentSet': currentSet,
    'startDate': startDate.toIso8601String(),
  };

  factory ActiveProgram.fromJson(Map<String, dynamic> json) => ActiveProgram(
    program: WorkoutProgram.fromJson(json['program'] as Map<String, dynamic>),
    currentDayIndex: json['currentDayIndex'] as int,
    currentExerciseIndex: json['currentExerciseIndex'] as int,
    currentSet: json['currentSet'] as int,
    startDate: DateTime.parse(json['startDate'] as String),
  );

  ActiveProgram copyWith({
    WorkoutProgram? program,
    int? currentDayIndex,
    int? currentExerciseIndex,
    int? currentSet,
    DateTime? startDate,
  }) {
    return ActiveProgram(
      program: program ?? this.program,
      currentDayIndex: currentDayIndex ?? this.currentDayIndex,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      startDate: startDate ?? this.startDate,
    );
  }
}
