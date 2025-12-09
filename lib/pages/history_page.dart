import 'package:flutter/material.dart';
import '../services/workout_history_service.dart';
import '../models/workout_models.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final WorkoutHistoryService _historyService = WorkoutHistoryService();
  List<WorkoutSession> _sessions = [];
  List<WorkoutSession> _filteredSessions = [];
  bool _isLoading = true;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tous'; // 'Tous', 'Semaine', 'Mois', '3 Mois'
  String _selectedExerciseFilter = 'Tous';
  Set<String> _allExercises = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _sessions.where((session) {
      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = session.sets.any((set) =>
            set.exercise.toLowerCase().contains(_searchQuery) ||
            (set.equipment?.toLowerCase().contains(_searchQuery) ?? false));
      }

      // Date filter
      bool matchesDate = true;
      final now = DateTime.now();
      switch (_selectedFilter) {
        case 'Semaine':
          matchesDate = session.date.isAfter(now.subtract(const Duration(days: 7)));
          break;
        case 'Mois':
          matchesDate = session.date.isAfter(now.subtract(const Duration(days: 30)));
          break;
        case '3 Mois':
          matchesDate = session.date.isAfter(now.subtract(const Duration(days: 90)));
          break;
      }

      // Exercise filter
      bool matchesExercise = true;
      if (_selectedExerciseFilter != 'Tous') {
        matchesExercise = session.sets.any((set) => set.exercise == _selectedExerciseFilter);
      }

      return matchesSearch && matchesDate && matchesExercise;
    }).toList();

    setState(() {
      _filteredSessions = filtered;
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final sessions = await _historyService.getAllSessions();

    // Extract all unique exercises
    Set<String> exercises = {};
    for (var session in sessions) {
      for (var set in session.sets) {
        exercises.add(set.exercise);
      }
    }

    setState(() {
      _sessions = sessions;
      _allExercises = exercises;
      _applyFilters();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF5C32E),
                ),
              )
            : _sessions.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFF5C32E),
      backgroundColor: const Color(0xFF101010),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "Aucune séance enregistrée",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Commence ton premier workout !",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Icon(
                  Icons.arrow_downward,
                  size: 24,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tire pour rafraîchir",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFF5C32E),
      backgroundColor: const Color(0xFF101010),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Historique",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (_sessions.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showClearConfirmation(),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: const Text(
                    "Effacer",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${_filteredSessions.length} séance${_filteredSessions.length > 1 ? 's' : ''} ${_selectedFilter != 'Tous' ? '($_selectedFilter)' : ''}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Color(0xFFF5C32E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un exercice...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: Icon(
                      Icons.clear,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date filters
                ...[
 'Tous',
                  'Semaine',
                  'Mois',
                  '3 Mois'
                ].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilters();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF5C32E)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF5C32E)
                                : Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Exercise filter
                if (_allExercises.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      setState(() {
                        _selectedExerciseFilter = value;
                        _applyFilters();
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'Tous',
                        child: Text(
                          'Tous les exercices',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ..._allExercises.map((exercise) {
                        return PopupMenuItem(
                          value: exercise,
                          child: Text(
                            exercise,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedExerciseFilter != 'Tous'
                            ? const Color(0xFFF5C32E)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedExerciseFilter != 'Tous'
                              ? const Color(0xFFF5C32E)
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: _selectedExerciseFilter != 'Tous'
                                ? Colors.black
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedExerciseFilter == 'Tous'
                                ? 'Exercice'
                                : _selectedExerciseFilter,
                            style: TextStyle(
                              color: _selectedExerciseFilter != 'Tous'
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedExerciseFilter != 'Tous'
                                ? Colors.black
                                : Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats Summary
          if (_filteredSessions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Stats filtrées',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlobalStat(
                          'Total reps',
                          _filteredSessions.fold(0, (sum, s) => sum + s.totalReps).toString(),
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGlobalStat(
                          'Total sets',
                          _filteredSessions.fold(0, (sum, s) => sum + s.sets.length).toString(),
                          Icons.format_list_numbered,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGlobalStat(
                          'Record',
                          _filteredSessions.map((s) => s.totalReps).reduce((a, b) => a > b ? a : b).toString(),
                          Icons.emoji_events,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Sessions list
          if (_filteredSessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Modifie tes filtres pour voir plus de séances',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._filteredSessions.map((session) => _buildSessionCard(session)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(WorkoutSession session) {
    // Calculate additional stats
    final exerciseGroups = <String, int>{};
    for (var set in session.sets) {
      exerciseGroups[set.exercise] = (exerciseGroups[set.exercise] ?? 0) + 1;
    }
    final avgTempo = session.sets.isEmpty
        ? 0.0
        : session.sets.where((s) => !s.isManual).map((s) => s.averageTempo).isEmpty
            ? 0.0
            : session.sets.where((s) => !s.isManual).map((s) => s.averageTempo).reduce((a, b) => a + b) /
                session.sets.where((s) => !s.isManual).length;
    final maxReps = session.sets.isEmpty ? 0 : session.sets.map((s) => s.reps).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: 18,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
              ),
            ),
            child: Center(
              child: Text(
                '${session.sets.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          title: Text(
            session.formattedDate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  session.formattedDuration,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.repeat,
                  size: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.totalReps} reps',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          iconColor: const Color(0xFFF5C32E),
          collapsedIconColor: Colors.white.withOpacity(0.6),
          children: [
            // Stats summary
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFFF5C32E),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Statistiques',
                        style: TextStyle(
                          color: Color(0xFFF5C32E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          'Total reps',
                          session.totalReps.toString(),
                          Icons.repeat,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatTile(
                          'Meilleur set',
                          '$maxReps reps',
                          Icons.star,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          'Tempo moyen',
                          avgTempo > 0 ? '${avgTempo.toStringAsFixed(1)}s' : 'N/A',
                          Icons.speed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatTile(
                          'Exercices',
                          exerciseGroups.length.toString(),
                          Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sets detail
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.list_alt,
                        color: Color(0xFFF5C32E),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Séries détaillées (${session.sets.length})',
                        style: const TextStyle(
                          color: Color(0xFFF5C32E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...session.sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final set = entry.value;
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: index < session.sets.length - 1 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      set.displayExercise,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (set.isManual)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5C32E).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Manuel',
                                          style: TextStyle(
                                            color: Color(0xFFF5C32E),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${set.reps} reps',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (set.weight != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.fitness_center,
                                        color: Colors.white.withOpacity(0.6),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${set.weight}kg',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (!set.isManual) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.speed,
                                        color: Colors.white.withOpacity(0.6),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        set.formattedTempo,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (set.equipment != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.build_circle_outlined,
                                        color: Colors.white.withOpacity(0.6),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        set.equipment!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Effacer l\'historique',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Veux-tu vraiment supprimer toutes tes séances ? Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAll();
      _loadHistory();
    }
  }

  Widget _buildGlobalStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFFF5C32E),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
