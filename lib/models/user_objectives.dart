import 'package:cloud_firestore/cloud_firestore.dart';

class UserObjectives {
  final String userId;
  final String objective; // Hypertrophie, Force, Perte de poids, Endurance, Équilibré
  final String level; // Débutant, Intermédiaire, Avancé
  final int frequency; // Nombre de séances par semaine
  final String splitType; // PPL, Upper/Lower, Full Body, Bro Split, GPT-Suggested
  final List<String> focusGroups; // Pecs, Dos, Épaules, Bras, Jambes, Core
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? generatedProgram; // Programme généré par GPT

  UserObjectives({
    required this.userId,
    required this.objective,
    required this.level,
    required this.frequency,
    required this.splitType,
    required this.focusGroups,
    required this.createdAt,
    this.updatedAt,
    this.generatedProgram,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'objective': objective,
      'level': level,
      'frequency': frequency,
      'splitType': splitType,
      'focusGroups': focusGroups,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'generatedProgram': generatedProgram,
    };
  }

  // Create from Firestore
  factory UserObjectives.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserObjectives(
      userId: data['userId'] as String,
      objective: data['objective'] as String,
      level: data['level'] as String,
      frequency: data['frequency'] as int,
      splitType: data['splitType'] as String,
      focusGroups: List<String>.from(data['focusGroups'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      generatedProgram: data['generatedProgram'] as Map<String, dynamic>?,
    );
  }

  // Copy with
  UserObjectives copyWith({
    String? userId,
    String? objective,
    String? level,
    int? frequency,
    String? splitType,
    List<String>? focusGroups,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? generatedProgram,
  }) {
    return UserObjectives(
      userId: userId ?? this.userId,
      objective: objective ?? this.objective,
      level: level ?? this.level,
      frequency: frequency ?? this.frequency,
      splitType: splitType ?? this.splitType,
      focusGroups: focusGroups ?? this.focusGroups,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      generatedProgram: generatedProgram ?? this.generatedProgram,
    );
  }
}
