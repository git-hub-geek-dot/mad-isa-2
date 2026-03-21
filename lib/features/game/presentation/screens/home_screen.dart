import 'package:dynamic_scenario_game/core/firebase/firebase_bootstrap.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/presentation/controllers/game_controller.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_history_entry.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.usesMockApi,
    required this.firebaseBootstrap,
  });

  final GameController controller;
  final bool usesMockApi;
  final FirebaseBootstrapResult firebaseBootstrap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GameCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.controller.lastCategory ?? GameCategory.presets.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorMessage = widget.controller.errorMessage;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8E3C5),
              Color(0xFFF7F1E7),
              Color(0xFFD7E0D8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusPill(
                      label: widget.usesMockApi
                          ? 'Mock AI mode'
                          : 'Backend API mode',
                    ),
                    const _StatusPill(label: '2-3 minute runs'),
                    const _StatusPill(label: 'Dark comedy'),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'AI-Based Dynamic Scenario Simulation Game',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 14),
                Text(
                  'Pick a chaos lane, press play, and survive four rounds of escalating consequences.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                _FirebaseStatusCard(firebaseBootstrap: widget.firebaseBootstrap),
                if (errorMessage != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(
                    message: errorMessage,
                    onDismiss: widget.controller.clearError,
                  ),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      if (widget.firebaseBootstrap.historyService != null) ...[
                        _HistorySection(
                          historyStream: widget.firebaseBootstrap.historyService!
                              .watchRecentRuns(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final category in GameCategory.presets) ...[
                        _CategoryCard(
                          category: category,
                          isSelected: category.id == _selectedCategory.id,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.controller.isBusy
                      ? null
                      : () => widget.controller.startGame(_selectedCategory),
                  child: widget.controller.isBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Play Scenario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FirebaseStatusCard extends StatelessWidget {
  const _FirebaseStatusCard({required this.firebaseBootstrap});

  final FirebaseBootstrapResult firebaseBootstrap;

  @override
  Widget build(BuildContext context) {
    final isReady = firebaseBootstrap.isReady;
    final background = isReady
        ? const Color(0xFF173D2D)
        : const Color(0xFFF4E5D0);
    final foreground = isReady ? const Color(0xFFF6EAD7) : const Color(0xFF1B1A18);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firebaseBootstrap.statusLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              isReady
                  ? 'Anonymous auth is active and completed runs will be saved to Firestore.'
                  : firebaseBootstrap.errorMessage ??
                      'Add Firebase app options with --dart-define values before auth and history can turn on.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground.withValues(alpha: 0.88),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.historyStream});

  final Stream<List<GameHistoryEntry>> historyStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<GameHistoryEntry>>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text('No saved runs yet. Finish one game and it will appear here.'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Runs',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final item in items) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.categoryTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.endingTitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.roastLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.roundsPlayed} rounds • ${_formatCompletedAt(item.completedAt)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF4E3C2D),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  String _formatCompletedAt(DateTime value) {
    final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $suffix';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final GameCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF1E1A1A),
                      Color(0xFF4E3C2D),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFFFFBF6),
                      Color(0xFFF2E4D2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E1A1A)
                  : const Color(0x1A1B1A18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B1A18).withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isSelected ? const Color(0xFFF6EAD7) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? const Color(0xFFF6EAD7).withValues(alpha: 0.92)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF8E2D1D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
