import 'package:dynamic_scenario_game/app/app.dart';
import 'package:dynamic_scenario_game/core/firebase/firebase_bootstrap.dart';
import 'package:dynamic_scenario_game/features/auth/data/firebase_auth_service.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:dynamic_scenario_game/features/game/domain/repositories/game_repository.dart';
import 'package:dynamic_scenario_game/features/game/presentation/controllers/game_controller.dart';
import 'package:dynamic_scenario_game/features/game/presentation/screens/game_screen.dart';
import 'package:dynamic_scenario_game/features/game/presentation/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders redesigned home screen', (tester) async {
    await tester.pumpWidget(const AiScenarioGameApp());
    await tester.pump();

    expect(find.text('Make one bad decision at a time.'), findsOneWidget);
    expect(find.text('Play Relationship Chaos'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
  });

  testWidgets('home screen offers guest and sign up when Firebase is ready', (
    tester,
  ) async {
    const authService = _FakeAuthService();
    final controller = GameController(
      repository: _FakeGameRepository(),
      authService: authService,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          controller: controller,
          usesMockApi: false,
          firebaseBootstrap: const FirebaseBootstrapResult(
            isConfigured: true,
            isReady: true,
            statusLabel: 'Firebase ready',
            authService: authService,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Continue As Guest'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Continue As Guest'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets(
    'game screen routes close and system back through the same handler',
    (tester) async {
      final controller = GameController(repository: _FakeGameRepository());
      await controller.startGame(GameCategory.presets.first);

      var closeRequests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            controller: controller,
            usesMockApi: false,
            onCloseRequested: () async {
              closeRequests += 1;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(closeRequests, 1);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(closeRequests, 2);
    },
  );
}

class _FakeGameRepository implements GameRepository {
  @override
  Future<GameSession> continueGame({
    required GameSession session,
    required ChoiceOption choice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GameSession> startGame({
    required GameCategory category,
    required int maxRounds,
  }) async {
    return GameSession(
      sessionId: 'session-1',
      categoryId: category.id,
      round: 1,
      maxRounds: maxRounds,
      scenario: 'A test scenario appears.',
      choices: const [
        ChoiceOption(id: 'a', text: 'Option A'),
        ChoiceOption(id: 'b', text: 'Option B'),
        ChoiceOption(id: 'c', text: 'Option C'),
      ],
      isFinal: false,
    );
  }
}

class _FakeAuthService implements FirebaseAuthService {
  const _FakeAuthService();

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  User? get currentUser => null;

  @override
  String? get currentUserId => null;

  @override
  bool get isSignedIn => false;

  @override
  bool get isAnonymous => false;

  @override
  String get identityLabel => 'Guest';

  @override
  Future<User?> ensureSignedIn() async => null;

  @override
  Future<User?> signInAsGuest() async => null;

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async => null;
}
