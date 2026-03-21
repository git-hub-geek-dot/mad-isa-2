import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
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
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isRestarting = false;

  Future<void> _handlePlayAgain() async {
    if (_isRestarting) {
      return;
    }

    setState(() {
      _isRestarting = true;
    });

    try {
      await widget.onPlayAgain();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restart the scenario.')),
      );
      setState(() {
        _isRestarting = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isRestarting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final category = GameCategory.fallbackById(session.categoryId);
    final presentation = _presentationFor(category);
    final theme = Theme.of(context);
    final endingTitle = session.endingTitle ?? 'Mission Complete';
    final roastLine =
        session.roastLine ??
        'You reached the ending with confidence that was not supported by the evidence.';

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              presentation.backdropTop,
              const Color(0xFF251C18),
              const Color(0xFFF2E2D1),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -60,
              child: _BackdropOrb(
                size: 260,
                colors: [
                  presentation.accent.withValues(alpha: 0.3),
                  presentation.accent.withValues(alpha: 0),
                ],
              ),
            ),
            const Positioned(
              left: -40,
              bottom: 90,
              child: _BackdropOrb(
                size: 210,
                colors: [Color(0x55FFF4E6), Color(0x00FFF4E6)],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ResultPill(
                          icon: presentation.icon,
                          label: category.title,
                        ),
                        _ResultPill(
                          icon: widget.usesMockApi
                              ? Icons.science_rounded
                              : Icons.auto_awesome_rounded,
                          label: widget.usesMockApi
                              ? 'Practice story'
                              : 'Live story',
                        ),
                        _ResultPill(
                          icon: Icons.flag_rounded,
                          label: '${session.maxRounds} rounds cleared',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ResultHero(
                              title: endingTitle,
                              roastLine: roastLine,
                              presentation: presentation,
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _OutcomeStat(
                                  label: 'Rounds',
                                  value:
                                      '${session.maxRounds}/${session.maxRounds}',
                                ),
                                _OutcomeStat(
                                  label: 'Category',
                                  value: presentation.shortLabel,
                                ),
                                _OutcomeStat(
                                  label: 'Ending vibe',
                                  value: presentation.toneLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _NarrativeCard(
                              icon: presentation.icon,
                              accent: presentation.accent,
                              title: 'How It Ended',
                              subtitle:
                                  'The final scene your choices unlocked.',
                              body: session.scenario,
                            ),
                            const SizedBox(height: 16),
                            _NarrativeCard(
                              icon: Icons.history_toggle_off_rounded,
                              accent: presentation.accent,
                              title: 'Aftermath',
                              subtitle:
                                  'This run is done. A replay will generate a fresh path and a new ending.',
                              body: presentation.aftermath,
                            ),
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1B1A18,
                                  ).withValues(alpha: 0.08),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next Move',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Run it again for a new ending, or go home and pick a completely different disaster lane.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _isRestarting ? null : _handlePlayAgain,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF8EDE0),
                        foregroundColor: const Color(0xFF231E1B),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _isRestarting
                            ? const SizedBox(
                                key: ValueKey('restart-loading'),
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Play Again',
                                key: ValueKey('restart-label'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isRestarting ? null : widget.onBackHome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF8EDE0),
                        side: BorderSide(
                          color: const Color(
                            0xFFF8EDE0,
                          ).withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Text('Back Home'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: size,
        width: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFF8EDE0)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF8EDE0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({
    required this.title,
    required this.roastLine,
    required this.presentation,
  });

  final String title;
  final String roastLine;
  final _ResultPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF171312), presentation.accent],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      presentation.icon,
                      color: const Color(0xFFF8EDE0),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENDING UNLOCKED',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(
                            0xFFF8EDE0,
                          ).withValues(alpha: 0.72),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: const Color(0xFFF8EDE0),
                          fontSize: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              roastLine,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFF8EDE0),
                fontSize: 24,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cue in presentation.cues) _HeroChip(label: cue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _OutcomeStat extends StatelessWidget {
  const _OutcomeStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF1B1A18).withValues(alpha: 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4E3C2D),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8EDE0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, color: const Color(0xFF1B1A18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4E3C2D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ResultPresentation {
  const _ResultPresentation({
    required this.icon,
    required this.accent,
    required this.backdropTop,
    required this.toneLabel,
    required this.shortLabel,
    required this.cues,
    required this.aftermath,
  });

  final IconData icon;
  final Color accent;
  final Color backdropTop;
  final String toneLabel;
  final String shortLabel;
  final List<String> cues;
  final String aftermath;
}

_ResultPresentation _presentationFor(GameCategory category) {
  switch (category.id) {
    case 'relationship_chaos':
      return const _ResultPresentation(
        icon: Icons.favorite_rounded,
        accent: Color(0xFF8C3C4F),
        backdropTop: Color(0xFF4F2430),
        toneLabel: 'Petty',
        shortLabel: 'Romance',
        cues: ['screenshots archived', 'ego bruised', 'timing fatal'],
        aftermath:
            'The relationship story is over for now, but the chat history will keep doing free overtime.',
      );
    case 'friendship_meltdown':
      return const _ResultPresentation(
        icon: Icons.groups_rounded,
        accent: Color(0xFF355B76),
        backdropTop: Color(0xFF213847),
        toneLabel: 'Messy',
        shortLabel: 'Group chat',
        cues: ['trust cracked', 'receipts saved', 'damage visible'],
        aftermath:
            'Someone will retell this version of events later, and it probably will not flatter you.',
      );
    case 'daily_absurdity':
      return const _ResultPresentation(
        icon: Icons.coffee_rounded,
        accent: Color(0xFF9A5A2B),
        backdropTop: Color(0xFF523013),
        toneLabel: 'Chaotic',
        shortLabel: 'Everyday',
        cues: ['tiny disaster', 'bad luck confirmed', 'normal day lost'],
        aftermath:
            'It started with something small and ended as a story you will be forced to explain too many times.',
      );
    default:
      return const _ResultPresentation(
        icon: Icons.bolt_rounded,
        accent: Color(0xFF72503D),
        backdropTop: Color(0xFF3D2D22),
        toneLabel: 'Wild',
        shortLabel: 'Chaos',
        cues: ['unstable outcome', 'confidence misplaced', 'receipt printed'],
        aftermath:
            'The ending is final, but the embarrassment still has excellent replay value.',
      );
  }
}
