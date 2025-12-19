import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymai/models/workout_models.dart';
import 'package:gymai/services/workout_post_service.dart';
import 'package:gymai/services/program_service.dart';
import 'package:gymai/models/program_models.dart';
import 'package:gymai/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkoutPostService _postService = WorkoutPostService();
  List<WorkoutPost> _posts = [];
  Map<String, dynamic> _stats = {};
  List<WorkoutProgram> _programs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final posts = await _postService.getAllPosts();
    final stats = await _postService.getStats();
    final programs = await ProgramService.getRecommendedPrograms();

    if (mounted) {
      setState(() {
        _posts = posts;
        _stats = stats;
        _programs = programs;
        _loading = false;
      });
    }
  }

  Future<void> _deletePost(String postId) async {
    await _postService.deletePost(postId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : RefreshIndicator(
              color: AppTheme.yellow,
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.black,
                    elevation: 0,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.yellow, AppTheme.orange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.fitness_center, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'GymAI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Overview
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.yellow, AppTheme.orange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tes stats',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatItem(
                                '${_stats['totalWorkouts'] ?? 0}',
                                'Séances',
                                Icons.fitness_center,
                              ),
                              _buildStatItem(
                                '${_stats['totalReps'] ?? 0}',
                                'Reps',
                                Icons.repeat,
                              ),
                              _buildStatItem(
                                '${_stats['thisWeekWorkouts'] ?? 0}',
                                'Cette semaine',
                                Icons.calendar_today,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Programs Section (if available)
                  if (_programs.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment, color: AppTheme.yellow, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Programmes recommandés',
                              style: TextStyle(
                                color: AppTheme.yellow,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          itemCount: _programs.length,
                          itemBuilder: (context, index) {
                            final program = _programs[index];
                            return _buildProgramCard(program);
                          },
                        ),
                      ),
                    ),
                  ],

                  // Feed Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_camera, color: AppTheme.yellow, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Ton feed',
                            style: TextStyle(
                              color: AppTheme.yellow,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_posts.length} posts',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Posts Feed
                  _posts.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Aucun post pour le moment',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Commence une séance pour créer ton premier post !',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPostCard(_posts[index]),
                            childCount: _posts.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(WorkoutProgram program) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                program.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${program.totalDays}j',
                  style: const TextStyle(
                    color: AppTheme.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            program.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            program.description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(WorkoutPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.yellow, AppTheme.orange],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        post.formattedPublishedTime,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54),
                  onPressed: () => _showDeleteConfirmation(post.id),
                ),
              ],
            ),
          ),

          // Photo (if available)
          if (post.photoPath != null && File(post.photoPath!).existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.file(
                File(post.photoPath!),
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),

          // Workout stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                if (post.caption != null && post.caption!.isNotEmpty) ...[
                  Text(
                    post.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Stats row
                Row(
                  children: [
                    _buildPostStat(
                      Icons.fitness_center,
                      '${post.session.sets.length} séries',
                    ),
                    const SizedBox(width: 16),
                    _buildPostStat(
                      Icons.repeat,
                      '${post.session.totalReps} reps',
                    ),
                    const SizedBox(width: 16),
                    _buildPostStat(
                      Icons.timer,
                      post.session.formattedDuration,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date and time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${post.session.formattedDate} " ${post.session.date.hour}:${post.session.date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.yellow, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Supprimer le post ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(postId);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
