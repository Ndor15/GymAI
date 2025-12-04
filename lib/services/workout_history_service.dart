import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_models.dart';

class WorkoutHistoryService {
  static final WorkoutHistoryService _instance =
      WorkoutHistoryService._internal();
  factory WorkoutHistoryService() => _instance;
  WorkoutHistoryService._internal();

  static const String _historyKey = 'workout_history';

  // Save a new workout session
  Future<void> saveSession(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing sessions
    final sessions = await getAllSessions();

    // Add new session
    sessions.insert(0, session); // Most recent first

    // Save back to storage
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));

    print("💾 Session saved: ${session.sets.length} sets, ${session.totalReps} total reps");
  }

  // Get all workout sessions
  Future<List<WorkoutSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => WorkoutSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get sessions for a specific date
  Future<List<WorkoutSession>> getSessionsForDate(DateTime date) async {
    final allSessions = await getAllSessions();
    final targetDate = DateTime(date.year, date.month, date.day);

    return allSessions.where((session) {
      final sessionDate = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      return sessionDate == targetDate;
    }).toList();
  }

  // Delete a session
  Future<void> deleteSession(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getAllSessions();

    sessions.removeWhere((s) =>
        s.date.isAtSameMomentAs(session.date) &&
        s.duration == session.duration);

    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Clear all history
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
