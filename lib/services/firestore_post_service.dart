import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:gymai/models/workout_models.dart';

class FirestorePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Add a new post to Firestore
  Future<void> addPost(WorkoutPost post, {String? localPhotoPath}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      String? photoUrl;

      // Upload photo to Firebase Storage if provided
      if (localPhotoPath != null && File(localPhotoPath).existsSync()) {
        photoUrl = await _uploadPhoto(localPhotoPath, post.id);
      }

      // Create post document
      final postData = {
        'id': post.id,
        'userId': _currentUserId,
        'session': post.session.toJson(),
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (post.caption != null) 'caption': post.caption,
        'publishedAt': Timestamp.fromDate(post.publishedAt),
      };

      await _firestore
          .collection('posts')
          .doc(post.id)
          .set(postData);

      // Update user stats
      await _updateUserStats(post.session);
    } catch (e) {
      print('Error adding post: $e');
      rethrow;
    }
  }

  // Upload photo to Firebase Storage
  Future<String> _uploadPhoto(String localPath, String postId) async {
    try {
      final file = File(localPath);
      final ref = _storage.ref().child('posts/$_currentUserId/$postId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading photo: $e');
      rethrow;
    }
  }

  // Update user workout stats
  Future<void> _updateUserStats(WorkoutSession session) async {
    if (_currentUserId == null) return;

    try {
      final userRef = _firestore.collection('users').doc(_currentUserId);
      await userRef.update({
        'totalWorkouts': FieldValue.increment(1),
        'totalReps': FieldValue.increment(session.totalReps),
      });
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Get all posts from current user
  Future<List<WorkoutPost>> getUserPosts() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutPost(
          id: data['id'] as String,
          session: WorkoutSession.fromJson(data['session'] as Map<String, dynamic>),
          photoPath: data['photoUrl'] as String?, // Note: using photoUrl from Firebase
          caption: data['caption'] as String?,
          publishedAt: (data['publishedAt'] as Timestamp).toDate(),
        );
      }).toList();

      // Sort in memory instead of using orderBy (avoids need for index)
      posts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return posts;
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }

  // Get feed posts (from followed users + own posts)
  Future<List<Map<String, dynamic>>> getFeedPosts() async {
    if (_currentUserId == null) return [];

    try {
      // Get user's following list
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final following = List<String>.from(userDoc.data()?['following'] ?? []);

      // Add current user to the list
      final userIds = [...following, _currentUserId!];

      // Get posts from these users (without orderBy to avoid index requirement)
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', whereIn: userIds.isEmpty ? [''] : userIds)
          .get();

      // Get user data for each post
      final posts = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;

        // Get user info
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();

        posts.add({
          'post': WorkoutPost(
            id: data['id'] as String,
            session: WorkoutSession.fromJson(data['session'] as Map<String, dynamic>),
            photoPath: data['photoUrl'] as String?,
            caption: data['caption'] as String?,
            publishedAt: (data['publishedAt'] as Timestamp).toDate(),
          ),
          'user': {
            'uid': userId,
            'username': userData?['username'] ?? 'Unknown',
            'displayName': userData?['displayName'],
            'photoURL': userData?['photoURL'],
          },
        });
      }

      // Sort in memory and limit to 50
      posts.sort((a, b) {
        final dateA = (a['post'] as WorkoutPost).publishedAt;
        final dateB = (b['post'] as WorkoutPost).publishedAt;
        return dateB.compareTo(dateA);
      });

      return posts.take(50).toList();
    } catch (e) {
      print('Error getting feed posts: $e');
      return [];
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    if (_currentUserId == null) return;

    try {
      // Get post to check ownership and get session data
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final data = postDoc.data()!;
      if (data['userId'] != _currentUserId) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete photo from storage if exists
      if (data['photoUrl'] != null) {
        try {
          final ref = _storage.ref().child('posts/$_currentUserId/$postId.jpg');
          await ref.delete();
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }

      // Revert user stats
      final session = WorkoutSession.fromJson(data['session'] as Map<String, dynamic>);
      await _firestore.collection('users').doc(_currentUserId).update({
        'totalWorkouts': FieldValue.increment(-1),
        'totalReps': FieldValue.increment(-session.totalReps),
      });

      // Delete post document
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Get user stats
  Future<Map<String, dynamic>> getStats() async {
    if (_currentUserId == null) {
      return {
        'totalWorkouts': 0,
        'totalReps': 0,
        'thisWeekWorkouts': 0,
      };
    }

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data();

      // Calculate this week's workouts - get all posts and filter in memory
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final allPosts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      // Filter in memory to avoid needing composite index
      final thisWeekPosts = allPosts.docs.where((doc) {
        final publishedAt = (doc.data()['publishedAt'] as Timestamp).toDate();
        return publishedAt.isAfter(weekAgo);
      }).length;

      return {
        'totalWorkouts': userData?['totalWorkouts'] ?? 0,
        'totalReps': userData?['totalReps'] ?? 0,
        'thisWeekWorkouts': thisWeekPosts,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {
        'totalWorkouts': 0,
        'totalReps': 0,
        'thisWeekWorkouts': 0,
      };
    }
  }

  // Like a post
  Future<void> toggleLike(String postId) async {
    if (_currentUserId == null) return;

    try {
      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(_currentUserId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
      } else {
        // Like
        await likeRef.set({
          'userId': _currentUserId,
          'likedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  // Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }

  // Check if current user liked a post
  Future<bool> isLikedByCurrentUser(String postId) async {
    if (_currentUserId == null) return false;

    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(_currentUserId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      print('Error checking like: $e');
      return false;
    }
  }

  // Follow/Unfollow user
  Future<void> toggleFollow(String targetUserId) async {
    if (_currentUserId == null || _currentUserId == targetUserId) return;

    try {
      final currentUserRef = _firestore.collection('users').doc(_currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      final currentUserDoc = await currentUserRef.get();
      final following = List<String>.from(currentUserDoc.data()?['following'] ?? []);

      if (following.contains(targetUserId)) {
        // Unfollow
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([targetUserId]),
        });
        await targetUserRef.update({
          'followers': FieldValue.arrayRemove([_currentUserId]),
        });
      } else {
        // Follow
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([targetUserId]),
        });
        await targetUserRef.update({
          'followers': FieldValue.arrayUnion([_currentUserId]),
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }
}
