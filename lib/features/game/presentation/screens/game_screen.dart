import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/presentation/controllers/game_controller.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.usesMockApi,
  });

  final GameController controller;
  final bool usesMockApi;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final category = session != null
        ? GameCategory.fallbackById(session.categoryId)
        : controller.lastCategory ?? GameCategory.presets.first;
    final presentation = _presentationFor(category);
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              presentation.backdropTop,
              const Color(0xFF251C18),
              const Color(0xFFF1E2D1),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -50,
              child: _BackdropOrb(
                size: 250,
                colors: [
                  presentation.accent.withValues(alpha: 0.28),
                  presentation.accent.withValues(alpha: 0),
                ],
              ),
            ),
            const Positioned(
              left: -30,
              bottom: 80,
              child: _BackdropOrb(
                size: 190,
                colors: [Color(0x66FFF4E6), Color(0x00FFF4E6)],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScreenHeader(
                      category: category,
                      presentation: presentation,
                      usesMockApi: usesMockApi,
                      onClose: controller.isBusy ? null : controller.backToHome,
                    ),
                    const SizedBox(height: 16),
                    _RoundHero(
                      category: category,
                      presentation: presentation,
                      session: session,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: session == null
                          ? const Center(child: CircularProgressIndicator())
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: SingleChildScrollView(
                                key: ValueKey(
                                  '${session.sessionId}-${session.round}',
                                ),
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (controller.errorMessage != null) ...[
                                      _InlineError(
                                        message: controller.errorMessage!,
                                        onDismiss: controller.clearError,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _ScenarioCard(
                                      scenario: session.scenario,
                                      presentation: presentation,
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionLead(
                                      title: 'Pick Your Move',
                                      subtitle: controller.isBusy
                                          ? 'Your last choice is being processed now.'
                                          : 'Three options. One consequence chain. Choose what kind of mess you want next.',
                                    ),
                                    const SizedBox(height: 12),
                                    for (final entry
                                        in session.choices.asMap().entries) ...[
                                      _ChoiceCard(
                                        index: entry.key,
                                        text: entry.value.text,
                                        accent: presentation.accent,
                                        enabled: !controller.isBusy,
                                        onTap: () => controller.selectChoice(
                                          entry.value,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    const SizedBox(height: 10),
                                    Text(
                                      'No rewind button. The story keeps the receipt.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: const Color(
                                              0xFFF6EAD7,
                                            ).withValues(alpha: 0.86),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: controller.isBusy
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _BusyFooter(accent: presentation.accent),
                            )
                          : const SizedBox.shrink(),
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

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.category,
    required this.presentation,
    required this.usesMockApi,
    required this.onClose,
  });

  final GameCategory category;
  final _GamePresentation presentation;
  final bool usesMockApi;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TopPill(
                icon: usesMockApi
                    ? Icons.science_rounded
                    : Icons.auto_awesome_rounded,
                label: usesMockApi ? 'Practice run' : 'Live story',
              ),
              _TopPill(icon: presentation.icon, label: category.title),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.label});

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
            Icon(icon, size: 16, color: const Color(0xFFF6EAD7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF6EAD7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundHero extends StatelessWidget {
  const _RoundHero({
    required this.category,
    required this.presentation,
    required this.session,
  });

  final GameCategory category;
  final _GamePresentation presentation;
  final dynamic session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundValue = session == null
        ? '--'
        : '${session.round}/${session.maxRounds}';
    final choiceCount = session == null ? '--' : '${session.choices.length}';
    final progress = session == null ? null : session.round / session.maxRounds;
    final remainingAfterThis = session == null
        ? null
        : session.maxRounds - session.round;

    final helperText = session == null
        ? 'The first turn is loading now.'
        : remainingAfterThis == 0
        ? 'Final move. After this, the ending lands.'
        : '$remainingAfterThis more decision${remainingAfterThis == 1 ? '' : 's'} after this before the ending.';

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
            Text(
              category.title.toUpperCase(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF6EAD7).withValues(alpha: 0.74),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose fast. Regret slowly.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFF6EAD7),
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              presentation.briefing,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFF6EAD7).withValues(alpha: 0.9),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(label: 'Round', value: roundValue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetric(label: 'Choices', value: choiceCount),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetric(
                    label: 'Tone',
                    value: presentation.toneLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF6EAD7)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              helperText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF6EAD7).withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
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
            color: const Color(0xFFF6EAD7),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF6EAD7).withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFF6EAD7),
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario, required this.presentation});

  final String scenario;
  final _GamePresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8EDE0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: presentation.accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
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
                    color: presentation.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      presentation.icon,
                      color: const Color(0xFF1B1A18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Situation',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Read the room before you answer.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4E3C2D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(scenario, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFFF6EAD7),
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFF6EAD7).withValues(alpha: 0.84),
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.index,
    required this.text,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final String text;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionLabel = 'Option ${String.fromCharCode(65 + index)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                enabled
                    ? Colors.white.withValues(alpha: 0.97)
                    : Colors.white.withValues(alpha: 0.78),
                accent.withValues(alpha: enabled ? 0.16 : 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.2 : 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: enabled ? 0.08 : 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ChoiceMarker(label: optionLabel, accent: accent),
                    const Spacer(),
                    Icon(
                      enabled
                          ? Icons.north_east_rounded
                          : Icons.hourglass_top_rounded,
                      color: const Color(
                        0xFF1B1A18,
                      ).withValues(alpha: enabled ? 1 : 0.46),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  enabled
                      ? 'Tap to commit this choice.'
                      : 'Locking this in and generating the next turn...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4E3C2D),
                    fontWeight: FontWeight.w600,
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

class _ChoiceMarker extends StatelessWidget {
  const _ChoiceMarker({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _BusyFooter extends StatelessWidget {
  const _BusyFooter({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8EDE0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Writing the consequence chain...',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD97757),
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
                  color: const Color(0xFF251F1A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(onPressed: onDismiss, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}

class _GamePresentation {
  const _GamePresentation({
    required this.icon,
    required this.accent,
    required this.backdropTop,
    required this.briefing,
    required this.cues,
    required this.toneLabel,
  });

  final IconData icon;
  final Color accent;
  final Color backdropTop;
  final String briefing;
  final List<String> cues;
  final String toneLabel;
}

_GamePresentation _presentationFor(GameCategory category) {
  switch (category.id) {
    case 'relationship_chaos':
      return const _GamePresentation(
        icon: Icons.favorite_rounded,
        accent: Color(0xFF8C3C4F),
        backdropTop: Color(0xFF4F2430),
        briefing:
            'Romance, ego, and suspicious timing are all active. Every reply has audience potential now.',
        cues: ['jealous energy', 'screenshots ready', 'public stakes'],
        toneLabel: 'Petty',
      );
    case 'friendship_meltdown':
      return const _GamePresentation(
        icon: Icons.groups_rounded,
        accent: Color(0xFF355B76),
        backdropTop: Color(0xFF213847),
        briefing:
            'The group dynamic is already unstable, and one more reckless decision can turn the chat into evidence.',
        cues: ['group tension', 'mixed loyalties', 'receipts incoming'],
        toneLabel: 'Messy',
      );
    case 'daily_absurdity':
      return const _GamePresentation(
        icon: Icons.coffee_rounded,
        accent: Color(0xFF9A5A2B),
        backdropTop: Color(0xFF523013),
        briefing:
            'This started as a normal day. It is now one impulsive tap away from becoming a documented incident.',
        cues: ['small disaster', 'bad luck', 'office folklore'],
        toneLabel: 'Chaotic',
      );
    default:
      return const _GamePresentation(
        icon: Icons.bolt_rounded,
        accent: Color(0xFF72503D),
        backdropTop: Color(0xFF3D2D22),
        briefing:
            'The situation is unstable, the confidence is misplaced, and the next choice will only make that gap louder.',
        cues: ['unpredictable', 'high risk', 'zero dignity'],
        toneLabel: 'Wild',
      );
  }
}
