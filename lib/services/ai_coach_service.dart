import 'package:cloud_functions/cloud_functions.dart';

class AICoachService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate initial workout program based on user objectives
  Future<Map<String, dynamic>> generateWorkoutProgram({
    required String objective,
    required String level,
    required int frequency,
    required String splitType,
    String? focusGroups,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateWorkoutProgram').call({
        'objective': objective,
        'level': level,
        'frequency': frequency,
        'splitType': splitType,
        'focusGroups': focusGroups,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Error generating workout program: $e');
      rethrow;
    }
  }

  /// Get exercise recommendation during workout
  Future<Map<String, dynamic>> getExerciseRecommendation({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> currentSession,
    required Map<String, dynamic> exerciseHistory,
    required Map<String, dynamic> recentTrends,
  }) async {
    try {
      final result = await _functions.httpsCallable('getExerciseRecommendation').call({
        'userProfile': userProfile,
        'currentSession': currentSession,
        'exerciseHistory': exerciseHistory,
        'recentTrends': recentTrends,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting exercise recommendation: $e');
      rethrow;
    }
  }

  /// Analyze progression and get adjustment recommendations
  Future<Map<String, dynamic>> analyzeProgression({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> exerciseHistory,
    required Map<String, dynamic> weeklyStats,
  }) async {
    try {
      final result = await _functions.httpsCallable('analyzeProgression').call({
        'userProfile': userProfile,
        'exerciseHistory': exerciseHistory,
        'weeklyStats': weeklyStats,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Error analyzing progression: $e');
      rethrow;
    }
  }
}
