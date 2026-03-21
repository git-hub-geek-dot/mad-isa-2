import 'package:dynamic_scenario_game/core/firebase/firebase_bootstrap.dart';
import 'package:dynamic_scenario_game/features/auth/data/firebase_auth_service.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/presentation/controllers/game_controller.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_history_entry.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late GameCategory _selectedCategory;
  late final AnimationController _entryController;
  bool _isAuthBusy = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.controller.lastCategory ?? GameCategory.presets.first;
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest(FirebaseAuthService authService) async {
    if (_isAuthBusy) {
      return;
    }

    setState(() {
      _isAuthBusy = true;
    });

    try {
      await authService.signInAsGuest();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Continuing as guest.')));
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (_) {
      _showMessage('Could not continue as guest. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
    }
  }

  Future<void> _openSignUpSheet(FirebaseAuthService authService) async {
    if (_isAuthBusy) {
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SignUpSheet(
          onSubmit: ({required name, required email, required password}) {
            return authService.signUp(
              name: name,
              email: email,
              password: password,
            );
          },
        );
      },
    );

    if (!mounted || created != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created successfully.')),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildEntrance({
    required double start,
    required double end,
    required Widget child,
    Offset beginOffset = const Offset(0, 0.05),
  }) {
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.controller.errorMessage;
    final authService = widget.firebaseBootstrap.authService;
    final historyService = widget.firebaseBootstrap.historyService;

    return StreamBuilder<Object?>(
      stream: authService?.authStateChanges(),
      builder: (context, _) {
        final identityLabel = authService?.identityLabel ?? 'Guest';
        final isSignedIn = authService?.isSignedIn ?? false;
        final isAnonymous = authService?.isAnonymous ?? false;
        final savesProgress = widget.firebaseBootstrap.isReady && isSignedIn;
        final showGuestChoice = authService != null && !isSignedIn;
        final showUpgradeChoice = authService != null && isAnonymous;
        final showHistory = historyService != null && isSignedIn;
        final identityIcon = isSignedIn && !isAnonymous
            ? Icons.waving_hand_rounded
            : Icons.person_rounded;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF6E4CF),
                  Color(0xFFF1D2C6),
                  Color(0xFFD8E4DC),
                ],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: -90,
                  right: -50,
                  child: _BackdropOrb(
                    size: 240,
                    colors: [Color(0x99FFF7EF), Color(0x00FFF7EF)],
                  ),
                ),
                const Positioned(
                  left: -40,
                  bottom: 110,
                  child: _BackdropOrb(
                    size: 180,
                    colors: [Color(0x66C46845), Color(0x00C46845)],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              _buildEntrance(
                                start: 0,
                                end: 0.18,
                                beginOffset: const Offset(0, 0.025),
                                child: _InfoBadge(
                                  icon: identityIcon,
                                  label: identityLabel,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildEntrance(
                                start: 0.06,
                                end: 0.34,
                                child: _HeroPanel(
                                  category: _selectedCategory,
                                  savesProgress: savesProgress,
                                ),
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 18),
                                _ErrorBanner(
                                  message: errorMessage,
                                  onDismiss: widget.controller.clearError,
                                ),
                              ],
                              _buildEntrance(
                                start: 0.16,
                                end: 0.58,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 28),
                                    const _SectionIntro(
                                      title: 'Pick Tonight\'s Disaster',
                                      subtitle:
                                          'Each category starts in a different flavor of trouble.',
                                    ),
                                    const SizedBox(height: 14),
                                    for (final category
                                        in GameCategory.presets) ...[
                                      _CategoryCard(
                                        category: category,
                                        isSelected:
                                            category.id == _selectedCategory.id,
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
                              _buildEntrance(
                                start: 0.3,
                                end: 0.78,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    _ProgressStatusCard(
                                      firebaseBootstrap:
                                          widget.firebaseBootstrap,
                                      isSignedIn: isSignedIn,
                                      isAnonymous: isAnonymous,
                                    ),
                                    if (showGuestChoice) ...[
                                      const SizedBox(height: 18),
                                      _AccountActionCard(
                                        title: 'Choose How You Want To Play',
                                        body:
                                            'Jump in as a guest for zero friction, or create an account if you want your endings tied to a real profile.',
                                        primaryLabel: 'Continue As Guest',
                                        secondaryLabel: 'Sign Up',
                                        onPrimaryTap: _isAuthBusy
                                            ? null
                                            : () =>
                                                  _continueAsGuest(authService),
                                        onSecondaryTap: _isAuthBusy
                                            ? null
                                            : () =>
                                                  _openSignUpSheet(authService),
                                        isBusy: _isAuthBusy,
                                      ),
                                    ] else if (showUpgradeChoice) ...[
                                      const SizedBox(height: 18),
                                      _AccountActionCard(
                                        title: 'Want A Proper Account?',
                                        body:
                                            'You are playing as a guest right now. Create an account any time and keep your progress linked to it.',
                                        primaryLabel: 'Sign Up',
                                        onPrimaryTap: _isAuthBusy
                                            ? null
                                            : () =>
                                                  _openSignUpSheet(authService),
                                        isBusy: _isAuthBusy,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (showHistory)
                                _buildEntrance(
                                  start: 0.46,
                                  end: 0.9,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 24),
                                      const _SectionIntro(
                                        title: 'Recent Endings',
                                        subtitle:
                                            'Your latest completed runs appear here automatically.',
                                      ),
                                      const SizedBox(height: 12),
                                      _HistorySection(
                                        historyStream: historyService
                                            .watchRecentRuns(),
                                      ),
                                    ],
                                  ),
                                ),
                              _buildEntrance(
                                start: 0.54,
                                end: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 24),
                                    const _SectionIntro(
                                      title: 'How It Works',
                                      subtitle:
                                          'Every run is short, fast, and built to escalate with each choice.',
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        const _HowItWorksCard(
                                          icon: Icons.explore_rounded,
                                          title: 'Pick A Lane',
                                          body:
                                              'Start with relationship drama, friendship fallout, or everyday nonsense.',
                                        ),
                                        const _HowItWorksCard(
                                          icon: Icons.touch_app_rounded,
                                          title: 'Choose Fast',
                                          body:
                                              'Each round gives you three bad ideas dressed up as decisions.',
                                        ),
                                        _HowItWorksCard(
                                          icon: Icons.emoji_events_rounded,
                                          title: 'Own The Ending',
                                          body: savesProgress
                                              ? 'Finished runs are saved automatically so you can show your best disasters.'
                                              : 'Every run still reaches a proper ending, even if you are just testing without an account.',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEntrance(
                          start: 0.66,
                          end: 1,
                          beginOffset: const Offset(0, 0.035),
                          child: FilledButton(
                            onPressed: widget.controller.isBusy
                                ? null
                                : () => widget.controller.startGame(
                                    _selectedCategory,
                                  ),
                            child: widget.controller.isBusy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Play ${_selectedCategory.title}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.category, required this.savesProgress});

  final GameCategory category;
  final bool savesProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = _presentationFor(category);

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
            color: const Color(0xFF1B1A18).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
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
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      presentation.icon,
                      color: const Color(0xFFF6EAD7),
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
                        'CHAOS SIMULATOR',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(
                            0xFFF6EAD7,
                          ).withValues(alpha: 0.72),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Make one bad decision at a time.',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: const Color(0xFFF6EAD7),
                          fontSize: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Pick a lane, survive four rounds, and see whether your confidence lasts longer than the consequences.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFF6EAD7).withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: DecoratedBox(
                key: ValueKey(category.id),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tonight\'s mess: ${category.title}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFF6EAD7),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        presentation.previewLine,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(
                            0xFFF6EAD7,
                          ).withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                const _HeroStat(value: '4', label: 'rounds'),
                const _HeroStat(value: '3', label: 'choices each'),
                _HeroStat(
                  value: savesProgress ? 'On' : 'Off',
                  label: 'auto-save',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: const Color(0xFFF6EAD7)),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF6EAD7).withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStatusCard extends StatelessWidget {
  const _ProgressStatusCard({
    required this.firebaseBootstrap,
    required this.isSignedIn,
    required this.isAnonymous,
  });

  final FirebaseBootstrapResult firebaseBootstrap;
  final bool isSignedIn;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final isReady = firebaseBootstrap.isReady;
    final isPositive = isReady && isSignedIn;
    final foreground = isPositive
        ? const Color(0xFFF6EAD7)
        : const Color(0xFF1B1A18);
    final background = isPositive
        ? const LinearGradient(colors: [Color(0xFF204938), Color(0xFF2A6550)])
        : const LinearGradient(colors: [Color(0xFFFFF5EA), Color(0xFFF0E1CF)]);

    final title = isReady
        ? isSignedIn
              ? isAnonymous
                    ? 'Playing as guest'
                    : 'Account connected'
              : 'Choose how you want to play'
        : 'Guest mode is active';

    final body = isReady
        ? isSignedIn
              ? isAnonymous
                    ? 'Your progress now saves to this guest profile. You can sign up later without losing that progress.'
                    : 'Your progress is attached to your account and recent endings will appear below.'
              : 'You can play immediately either way. Use guest mode for speed, or sign up if you want a named account.'
        : firebaseBootstrap.errorMessage ??
              'You can still play the full experience, but recent runs will not be saved on this device.';

    final icon = isReady
        ? isSignedIn
              ? isAnonymous
                    ? Icons.person_outline_rounded
                    : Icons.verified_user_rounded
              : Icons.badge_rounded
        : Icons.person_outline_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: background,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFF1B1A18).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: foreground),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
    this.isBusy = false,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF1B1A18).withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: onPrimaryTap,
                  child: isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(primaryLabel),
                ),
                if (secondaryLabel != null)
                  OutlinedButton(
                    onPressed: onSecondaryTap,
                    child: Text(secondaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF1B1A18).withValues(alpha: 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1A18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: const Color(0xFFF6EAD7), size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4E3C2D)),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.historyStream});

  final Stream<List<GameHistoryEntry>> historyStream;

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFF1B1A18).withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1A18).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.history_rounded),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No endings saved yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1A18),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Finish one full run and your latest result will appear here as a saved highlight card.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final item in items) ...[
              _HistoryRunCard(
                item: item,
                completedAtLabel: _formatCompletedAt(item.completedAt),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  String _formatCompletedAt(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $suffix';
  }
}

class _HistoryRunCard extends StatelessWidget {
  const _HistoryRunCard({required this.item, required this.completedAtLabel});

  final GameHistoryEntry item;
  final String completedAtLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = GameCategory.presets.firstWhere(
      (candidate) => candidate.title == item.categoryTitle,
      orElse: () => GameCategory.presets.first,
    );
    final presentation = _presentationFor(category);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            presentation.accent.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: presentation.accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1A18).withValues(alpha: 0.06),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: presentation.accent.withValues(alpha: 0.14),
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
                        item.categoryTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        completedAtLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4E3C2D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1A18).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      '${item.roundsPlayed} rounds',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.endingTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.roastLine,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1B1A18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
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
    final presentation = _presentationFor(category);
    final foreground = isSelected
        ? const Color(0xFFF6EAD7)
        : const Color(0xFF1B1A18);

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      scale: isSelected ? 1 : 0.985,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [const Color(0xFF1A1514), presentation.accent],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFFBF6), Color(0xFFF2E4D2)],
                    ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0x1A1B1A18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B1A18).withValues(alpha: 0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.14)
                          : presentation.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        presentation.icon,
                        color: foreground,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                category.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: foreground,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: foreground.withValues(
                                alpha: isSelected ? 1 : 0.36,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in presentation.tags)
                              _CategoryTag(label: tag, isSelected: isSelected),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? const Color(0xFFF6EAD7)
        : const Color(0xFF1B1A18);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFF1B1A18).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CategoryPresentation {
  const _CategoryPresentation({
    required this.icon,
    required this.accent,
    required this.tags,
    required this.previewLine,
  });

  final IconData icon;
  final Color accent;
  final List<String> tags;
  final String previewLine;
}

class _SignUpSheet extends StatefulWidget {
  const _SignUpSheet({required this.onSubmit});

  final Future<void> Function({
    required String name,
    required String email,
    required String password,
  })
  onSubmit;

  @override
  State<_SignUpSheet> createState() => _SignUpSheetState();
}

class _SignUpSheetState extends State<_SignUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = _friendlyAuthError(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not create the account. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF8EDE0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1A18).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1A18).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Optional account',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Create an account',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your details if you want a named profile. If you are already playing as a guest, this upgrades that guest profile instead of replacing it.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.54),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1B1A18).withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.security_rounded, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can keep playing as Anonymous and sign up later. Creating an account is optional.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty || !text.contains('@')) {
                        return 'Enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _SheetError(message: _errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can always stay in guest mode and sign up later from the home screen.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4E3C2D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF8E2D1D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8E2D1D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

_CategoryPresentation _presentationFor(GameCategory category) {
  switch (category.id) {
    case 'relationship_chaos':
      return const _CategoryPresentation(
        icon: Icons.favorite_rounded,
        accent: Color(0xFF8C3C4F),
        tags: ['screenshots', 'jealousy', 'bad timing'],
        previewLine:
            'Romance, ego, and social media all enter the room at once. None of them are here to help.',
      );
    case 'friendship_meltdown':
      return const _CategoryPresentation(
        icon: Icons.groups_rounded,
        accent: Color(0xFF355B76),
        tags: ['group chat', 'betrayal', 'damage control'],
        previewLine:
            'One suspicious rename, one deleted message, and suddenly the chat feels like a courtroom.',
      );
    case 'daily_absurdity':
      return const _CategoryPresentation(
        icon: Icons.coffee_rounded,
        accent: Color(0xFF9A5A2B),
        tags: ['office chaos', 'weird luck', 'tiny disasters'],
        previewLine:
            'A normal day tries very hard to stay normal, and fails almost immediately.',
      );
    default:
      return const _CategoryPresentation(
        icon: Icons.bolt_rounded,
        accent: Color(0xFF72503D),
        tags: ['chaos', 'choices', 'consequences'],
        previewLine:
            'You are one tap away from a sequence of events with no adult supervision.',
      );
  }
}

String _friendlyAuthError(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'That email is already in use. Try another one.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'weak-password':
      return 'Use a stronger password with at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email sign-up is not enabled in Firebase yet.';
    case 'credential-already-in-use':
      return 'That email is already attached to another account.';
    case 'provider-already-linked':
      return 'This guest profile is already linked to an account.';
    default:
      return error.message ?? 'Authentication failed. Try again.';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

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
