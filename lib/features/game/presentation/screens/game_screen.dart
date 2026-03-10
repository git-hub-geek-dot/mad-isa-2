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
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF251F1A),
              Color(0xFF4E362A),
              Color(0xFFF0E4D5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _TopPill(
                            label: usesMockApi ? 'Mock AI' : 'Live API',
                          ),
                          if (session != null)
                            _TopPill(
                              label: 'Round ${session.round}/${session.maxRounds}',
                            ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed:
                          controller.isBusy ? null : controller.backToHome,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose fast. Regret slowly.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFF6EAD7),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value:
                        session == null ? null : session.round / session.maxRounds,
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: session == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
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
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8EDE0),
                                  borderRadius: BorderRadius.circular(30),
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
                                  child: Text(
                                    session.scenario,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Your options',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFFF6EAD7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final choice in session.choices) ...[
                                _ChoiceButton(
                                  text: choice.text,
                                  enabled: !controller.isBusy,
                                  onTap: () => controller.selectChoice(choice),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                ),
                if (controller.isBusy)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onDismiss,
  });

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
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
