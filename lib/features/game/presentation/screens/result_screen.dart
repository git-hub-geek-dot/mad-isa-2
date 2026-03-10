import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.session,
    required this.usesMockApi,
    required this.onPlayAgain,
    required this.onBackHome,
  });

  final GameSession session;
  final bool usesMockApi;
  final Future<void> Function() onPlayAgain;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final category = GameCategory.fallbackById(session.categoryId);
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Color(0xFFF9D7B8),
              Color(0xFFE9C8AF),
              Color(0xFF231E1B),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ResultPill(label: category.title),
                    _ResultPill(label: usesMockApi ? 'Mock AI' : 'Live API'),
                    _ResultPill(label: '${session.maxRounds} rounds cleared'),
                  ],
                ),
                const Spacer(),
                Text(
                  session.endingTitle ?? 'Mission Complete',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: const Color(0xFFF8EDE0),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  session.roastLine ??
                      'You reached the ending with confidence that was not supported by the evidence.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFF8EDE0),
                    fontSize: 24,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  session.scenario,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFF8EDE0).withValues(alpha: 0.88),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onPlayAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF8EDE0),
                    foregroundColor: const Color(0xFF231E1B),
                  ),
                  child: const Text('Play Again'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onBackHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF8EDE0),
                    side: BorderSide(
                      color: const Color(0xFFF8EDE0).withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Text('Back Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF8EDE0),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
