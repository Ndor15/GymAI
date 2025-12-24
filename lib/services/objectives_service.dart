import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymai/models/user_objectives.dart';
import 'package:gymai/services/ai_coach_service.dart';

class ObjectivesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AICoachService _aiCoach = AICoachService();

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Save user objectives and generate program with GPT
  Future<void> saveObjectives(UserObjectives objectives) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      // Save objectives to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('objectives')
          .doc('current')
          .set(objectives.toFirestore());

      print('✅ Objectives saved to Firestore');
    } catch (e) {
      print('Error saving objectives: $e');
      rethrow;
    }
  }

  /// Generate workout program using GPT
  Future<Map<String, dynamic>> generateProgram(UserObjectives objectives) async {
    try {
      print('🤖 Calling GPT to generate program...');

      final result = await _aiCoach.generateWorkoutProgram(
        objective: objectives.objective,
        level: objectives.level,
        frequency: objectives.frequency,
        splitType: objectives.splitType,
        focusGroups: objectives.focusGroups.join(', '),
      );

      if (result['success'] == true) {
        print('✅ Program generated successfully');
        return result['program'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to generate program');
      }
    } catch (e) {
      print('Error generating program: $e');
      rethrow;
    }
  }

  /// Save generated program to objectives
  Future<void> saveGeneratedProgram(Map<String, dynamic> program) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('objectives')
          .doc('current')
          .update({
        'generatedProgram': program,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Generated program saved to Firestore');
    } catch (e) {
      print('Error saving generated program: $e');
      rethrow;
    }
  }

  /// Get current user objectives
  Future<UserObjectives?> getCurrentObjectives() async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('objectives')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      return UserObjectives.fromFirestore(doc);
    } catch (e) {
      print('Error getting objectives: $e');
      return null;
    }
  }

  /// Check if user has completed objectives setup
  Future<bool> hasCompletedSetup() async {
    final objectives = await getCurrentObjectives();
    return objectives != null;
  }

  /// Delete objectives (reset)
  Future<void> deleteObjectives() async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('objectives')
          .doc('current')
          .delete();

      print('✅ Objectives deleted');
    } catch (e) {
      print('Error deleting objectives: $e');
      rethrow;
    }
  }
}
