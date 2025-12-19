import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymai/models/workout_models.dart';

class WorkoutPostService {
  static const String _postsKey = 'workout_posts';

  // Get all posts (sorted by most recent first)
  Future<List<WorkoutPost>> getAllPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getString(_postsKey);

    if (postsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(postsJson);
    final posts = decoded
        .map((json) => WorkoutPost.fromJson(json as Map<String, dynamic>))
        .toList();

    // Sort by published date (most recent first)
    posts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return posts;
  }

  // Add a new post
  Future<void> addPost(WorkoutPost post) async {
    final posts = await getAllPosts();
    posts.insert(0, post); // Add at the beginning

    await _savePosts(posts);
  }

  // Delete a post by ID
  Future<void> deletePost(String postId) async {
    final posts = await getAllPosts();
    posts.removeWhere((post) => post.id == postId);

    await _savePosts(posts);
  }

  // Private helper to save posts
  Future<void> _savePosts(List<WorkoutPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(posts.map((p) => p.toJson()).toList());
    await prefs.setString(_postsKey, encoded);
  }

  // Get stats for the home feed
  Future<Map<String, dynamic>> getStats() async {
    final posts = await getAllPosts();

    if (posts.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalReps': 0,
        'totalDuration': Duration.zero,
        'thisWeekWorkouts': 0,
      };
    }

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    final thisWeekPosts = posts.where((post) =>
        post.publishedAt.isAfter(oneWeekAgo)).toList();

    final totalReps = posts.fold<int>(
      0,
      (sum, post) => sum + post.session.totalReps,
    );

    final totalDuration = posts.fold<Duration>(
      Duration.zero,
      (sum, post) => sum + post.session.duration,
    );

    return {
      'totalWorkouts': posts.length,
      'totalReps': totalReps,
      'totalDuration': totalDuration,
      'thisWeekWorkouts': thisWeekPosts.length,
    };
  }
}
