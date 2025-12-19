import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String? displayName;
  final String? bio;
  final String? photoURL; // URL Firebase Storage
  final DateTime createdAt;
  final List<String> followers; // List of user IDs
  final List<String> following; // List of user IDs
  final int totalWorkouts;
  final int totalReps;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.displayName,
    this.bio,
    this.photoURL,
    required this.createdAt,
    this.followers = const [],
    this.following = const [],
    this.totalWorkouts = 0,
    this.totalReps = 0,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'username': username,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (photoURL != null) 'photoURL': photoURL,
        'createdAt': Timestamp.fromDate(createdAt),
        'followers': followers,
        'following': following,
        'totalWorkouts': totalWorkouts,
        'totalReps': totalReps,
      };

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      username: data['username'] as String,
      displayName: data['displayName'] as String?,
      bio: data['bio'] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      totalWorkouts: data['totalWorkouts'] as int? ?? 0,
      totalReps: data['totalReps'] as int? ?? 0,
    );
  }

  // Getters for stats
  int get followersCount => followers.length;
  int get followingCount => following.length;

  // Check if user follows another user
  bool isFollowing(String userId) => following.contains(userId);

  // Copy with method for updates
  AppUser copyWith({
    String? displayName,
    String? bio,
    String? photoURL,
    List<String>? followers,
    List<String>? following,
    int? totalWorkouts,
    int? totalReps,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalReps: totalReps ?? this.totalReps,
    );
  }
}
