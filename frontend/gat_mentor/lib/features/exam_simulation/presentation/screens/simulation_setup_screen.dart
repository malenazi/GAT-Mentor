import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/simulation_provider.dart';

class SimulationSetupScreen extends ConsumerStatefulWidget {
  const SimulationSetupScreen({super.key});

  @override
  ConsumerState<SimulationSetupScreen> createState() =>
      _SimulationSetupScreenState();
}

class _SimulationSetupScreenState
    extends ConsumerState<SimulationSetupScreen> {
  int _questionCount = 10;
  String? _selectedDifficulty;
  int? _selectedTopicId;
  bool _isStarting = false;

  // Placeholder topics; in production these would come from a topics provider.
  final List<Map<String, dynamic>> _topics = const [
    {'id': 1, 'name': 'Verbal Reasoning'},
    {'id': 2, 'name': 'Quantitative Reasoning'},
    {'id': 3, 'name': 'Analytical Reasoning'},
  ];

  final List<String> _difficulties = const ['easy', 'medium', 'hard'];

  Future<void> _startSimulation() async {
    setState(() => _isStarting = true);

    try {
      await ref.read(simulationProvider.notifier).startSession(
            type: 'simulation',
            questionCount: _questionCount,
            topicId: _selectedTopicId,
            difficulty: _selectedDifficulty,
          );

      final sessionId = ref.read(simulationProvider).sessionId;
      if (sessionId != null && mounted) {
        context.go('/simulation/run/$sessionId');
      }
    } catch (_) {
      // Error is handled in the provider state.
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Simulation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Simulate a Real Exam',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No hints, no immediate feedback.\nTest yourself under exam conditions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Question Count
            const Text(
              'Number of Questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 5, label: Text('5')),
                  ButtonSegment(value: 10, label: Text('10')),
                  ButtonSegment(value: 20, label: Text('20')),
                ],
                selected: {_questionCount},
                onSelectionChanged: (values) {
                  setState(() => _questionCount = values.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Topic Filter (optional)
            const Text(
              'Filter by Topic (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _selectedTopicId,
              decoration: const InputDecoration(
                hintText: 'All Topics',
                prefixIcon: Icon(Icons.topic_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Topics'),
                ),
                ..._topics.map((t) => DropdownMenuItem<int?>(
                      value: t['id'] as int,
                      child: Text(t['name'] as String),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedTopicId = value);
              },
            ),

            const SizedBox(height: 28),

            // Difficulty (optional)
            const Text(
              'Difficulty Preference (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                hintText: 'Mixed',
                prefixIcon: Icon(Icons.speed_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Mixed'),
                ),
                ..._difficulties.map((d) => DropdownMenuItem<String?>(
                      value: d,
                      child: Text(
                        d[0].toUpperCase() + d.substring(1),
                      ),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedDifficulty = value);
              },
            ),

            const SizedBox(height: 16),

            // Info card
            Card(
              color: AppColors.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will have ${_questionCount * 90 ~/ 60} minutes '
                        'to complete $_questionCount questions.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Error message
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.wrongBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : _startSimulation,
                icon: _isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isStarting ? 'Starting...' : 'Start Simulation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
