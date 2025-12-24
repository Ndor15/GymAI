import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymai/models/user_objectives.dart';
import 'package:gymai/services/objectives_service.dart';
import 'package:gymai/theme/app_theme.dart';

class SetupObjectivesPage extends StatefulWidget {
  const SetupObjectivesPage({super.key});

  @override
  State<SetupObjectivesPage> createState() => _SetupObjectivesPageState();
}

class _SetupObjectivesPageState extends State<SetupObjectivesPage> {
  final ObjectivesService _objectivesService = ObjectivesService();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _isGenerating = false;

  // Réponses
  String? _selectedObjective;
  String? _selectedLevel;
  int? _selectedFrequency;
  String? _selectedSplitType;
  final List<String> _selectedFocusGroups = [];

  final List<Map<String, dynamic>> _objectives = [
    {'value': 'Hypertrophie', 'icon': '💪', 'description': 'Gagner du muscle'},
    {'value': 'Force', 'icon': '🏋️', 'description': 'Devenir plus fort'},
    {'value': 'Perte de poids', 'icon': '🔥', 'description': 'Perdre du gras'},
    {'value': 'Endurance', 'icon': '🏃', 'description': 'Améliorer l\'endurance'},
    {'value': 'Équilibré', 'icon': '🎯', 'description': 'Mix de tout'},
  ];

  final List<Map<String, dynamic>> _levels = [
    {'value': 'Débutant', 'icon': '🟢', 'description': '< 6 mois'},
    {'value': 'Intermédiaire', 'icon': '🟡', 'description': '6 mois - 2 ans'},
    {'value': 'Avancé', 'icon': '🔴', 'description': '2+ ans'},
  ];

  final List<Map<String, dynamic>> _frequencies = [
    {'value': 3, 'icon': '📅', 'description': '2-3 séances/semaine'},
    {'value': 5, 'icon': '📆', 'description': '4-5 séances/semaine'},
    {'value': 6, 'icon': '🗓️', 'description': '6+ séances/semaine'},
  ];

  final List<Map<String, dynamic>> _splitTypes = [
    {'value': 'PPL', 'icon': '🔄', 'description': 'Push/Pull/Legs'},
    {'value': 'Upper/Lower', 'icon': '↕️', 'description': 'Haut/Bas du corps'},
    {'value': 'Full Body', 'icon': '🎯', 'description': 'Corps entier'},
    {'value': 'Bro Split', 'icon': '💪', 'description': '1 groupe/jour'},
    {'value': 'GPT-Suggested', 'icon': '🤖', 'description': 'GPT me conseille'},
  ];

  final List<Map<String, dynamic>> _focusGroups = [
    {'value': 'Pecs', 'icon': '🦅'},
    {'value': 'Dos', 'icon': '🦬'},
    {'value': 'Épaules', 'icon': '🏔️'},
    {'value': 'Bras', 'icon': '💪'},
    {'value': 'Jambes', 'icon': '🦵'},
    {'value': 'Core', 'icon': '🧱'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    if (_selectedObjective == null ||
        _selectedLevel == null ||
        _selectedFrequency == null ||
        _selectedSplitType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci de répondre à toutes les questions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Create objectives
      final objectives = UserObjectives(
        userId: userId,
        objective: _selectedObjective!,
        level: _selectedLevel!,
        frequency: _selectedFrequency!,
        splitType: _selectedSplitType!,
        focusGroups: _selectedFocusGroups.isEmpty ? ['Équilibré'] : _selectedFocusGroups,
        createdAt: DateTime.now(),
      );

      // Save objectives
      await _objectivesService.saveObjectives(objectives);

      // Generate program with GPT
      final program = await _objectivesService.generateProgram(objectives);

      // Save generated program
      await _objectivesService.saveGeneratedProgram(program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Ton programme a été généré avec succès !'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedObjective != null;
      case 1:
        return _selectedLevel != null;
      case 2:
        return _selectedFrequency != null;
      case 3:
        return _selectedSplitType != null;
      case 4:
        return true; // Focus groups is optional
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Mes objectifs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.yellow),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildObjectivePage(),
                _buildLevelPage(),
                _buildFrequencyPage(),
                _buildSplitTypePage(),
                _buildFocusGroupsPage(),
              ],
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _canProceed() && !_isGenerating ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellow,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade700,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      _currentPage == 4 ? 'Générer mon programme' : 'Suivant',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivePage() {
    return _buildQuestionPage(
      question: 'Quel est ton objectif principal ?',
      options: _objectives,
      selectedValue: _selectedObjective,
      onSelect: (value) => setState(() => _selectedObjective = value),
    );
  }

  Widget _buildLevelPage() {
    return _buildQuestionPage(
      question: 'Quel est ton niveau actuel ?',
      options: _levels,
      selectedValue: _selectedLevel,
      onSelect: (value) => setState(() => _selectedLevel = value),
    );
  }

  Widget _buildFrequencyPage() {
    return _buildQuestionPage(
      question: 'Combien de séances par semaine ?',
      options: _frequencies,
      selectedValue: _selectedFrequency,
      onSelect: (value) => setState(() => _selectedFrequency = value),
    );
  }

  Widget _buildSplitTypePage() {
    return _buildQuestionPage(
      question: 'Quel type de split préfères-tu ?',
      options: _splitTypes,
      selectedValue: _selectedSplitType,
      onSelect: (value) => setState(() => _selectedSplitType = value),
    );
  }

  Widget _buildFocusGroupsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Groupes musculaires à prioriser ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '(Optionnel - laisse vide pour un développement équilibré)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _focusGroups.map((group) {
              final isSelected = _selectedFocusGroups.contains(group['value']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFocusGroups.remove(group['value']);
                    } else {
                      _selectedFocusGroups.add(group['value'] as String);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.yellow.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.yellow : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(group['icon'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        group['value'] as String,
                        style: TextStyle(
                          color: isSelected ? AppTheme.yellow : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage({
    required String question,
    required List<Map<String, dynamic>> options,
    required dynamic selectedValue,
    required Function(dynamic) onSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          ...options.map((option) {
            final isSelected = selectedValue == option['value'];
            return GestureDetector(
              onTap: () => onSelect(option['value']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.yellow.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.yellow : Colors.white.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      option['icon'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['value'].toString(),
                            style: TextStyle(
                              color: isSelected ? AppTheme.yellow : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (option['description'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              option['description'] as String,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.yellow,
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
