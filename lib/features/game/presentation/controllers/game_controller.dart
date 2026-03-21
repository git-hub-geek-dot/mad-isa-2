import 'package:dynamic_scenario_game/core/config/app_config.dart';
import 'package:dynamic_scenario_game/core/network/game_api_exception.dart';
import 'package:dynamic_scenario_game/features/auth/data/firebase_auth_service.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:dynamic_scenario_game/features/game/domain/repositories/game_repository.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_run_history.dart';
import 'package:dynamic_scenario_game/features/history/domain/repositories/game_history_service.dart';
import 'package:flutter/foundation.dart';

enum GameStage {
  idle,
  starting,
  awaitingChoice,
  submittingChoice,
  completed,
}

class GameController extends ChangeNotifier {
  GameController({
    required GameRepository repository,
    FirebaseAuthService? authService,
    GameHistoryService? historyService,
  })  : _repository = repository,
        _authService = authService,
        _historyService = historyService;

  final GameRepository _repository;
  final FirebaseAuthService? _authService;
  final GameHistoryService? _historyService;

  GameStage _stage = GameStage.idle;
  GameStage get stage => _stage;

  GameSession? _session;
  GameSession? get session => _session;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GameCategory? _lastCategory;
  GameCategory? get lastCategory => _lastCategory;

  final List<_TurnDraft> _turnDrafts = [];

  bool get isBusy =>
      _stage == GameStage.starting || _stage == GameStage.submittingChoice;

  Future<void> startGame(GameCategory category) async {
    if (isBusy) {
      return;
    }

    _lastCategory = category;
    _errorMessage = null;
    _session = null;
    _turnDrafts.clear();
    _stage = GameStage.starting;
    notifyListeners();

    try {
      await _authService?.ensureSignedIn();
      final nextSession = await _repository.startGame(
        category: category,
        maxRounds: AppConfig.defaultRounds,
      );
      _session = nextSession;
      _captureIncomingTurn(nextSession);
      _stage = nextSession.isFinal
          ? GameStage.completed
          : GameStage.awaitingChoice;
    } catch (error) {
      _stage = GameStage.idle;
      _errorMessage = _toMessage(error);
    }

    notifyListeners();
  }

  Future<void> selectChoice(ChoiceOption choice) async {
    final currentSession = _session;
    if (currentSession == null || isBusy) {
      return;
    }

    _errorMessage = null;
    _stage = GameStage.submittingChoice;
    _setSelectionForCurrentTurn(choice);
    notifyListeners();

    try {
      final nextSession = await _repository.continueGame(
        session: currentSession,
        choice: choice,
      );
      _session = nextSession;

      if (nextSession.isFinal) {
        _stage = GameStage.completed;
        await _saveHistory(nextSession);
      } else {
        _captureIncomingTurn(nextSession);
        _stage = GameStage.awaitingChoice;
      }
    } catch (error) {
      _stage = GameStage.awaitingChoice;
      _errorMessage = _toMessage(error);
    }

    notifyListeners();
  }

  Future<void> playAgain() async {
    final category = _lastCategory;
    if (category == null) {
      backToHome();
      return;
    }

    await startGame(category);
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void backToHome() {
    _errorMessage = null;
    _session = null;
    _turnDrafts.clear();
    _stage = GameStage.idle;
    notifyListeners();
  }

  Future<void> _saveHistory(GameSession finalSession) async {
    final historyService = _historyService;
    final category = _lastCategory;
    if (historyService == null || category == null) {
      return;
    }

    final run = GameRunHistory(
      sessionId: finalSession.sessionId,
      categoryId: category.id,
      categoryTitle: category.title,
      roundsPlayed: _turnDrafts.length,
      completedAt: DateTime.now(),
      endingTitle: finalSession.endingTitle ?? 'Mission Complete',
      roastLine: finalSession.roastLine ?? '',
      endingScenario: finalSession.scenario,
      turns: [
        for (final draft in _turnDrafts)
          GameTurnHistory(
            round: draft.round,
            scenario: draft.scenario,
            choiceTexts: draft.choiceTexts,
            selectedChoiceId: draft.selectedChoiceId,
            selectedChoiceText: draft.selectedChoiceText,
          ),
      ],
    );

    try {
      await historyService.saveCompletedRun(run);
    } catch (error) {
      debugPrint('Failed to save run history: $error');
    }
  }

  void _captureIncomingTurn(GameSession session) {
    if (session.isFinal) {
      return;
    }

    _turnDrafts.removeWhere((draft) => draft.round == session.round);
    _turnDrafts.add(
      _TurnDraft(
        round: session.round,
        scenario: session.scenario,
        choiceTexts: session.choices.map((choice) => choice.text).toList(),
      ),
    );
  }

  void _setSelectionForCurrentTurn(ChoiceOption choice) {
    final currentRound = _session?.round;
    if (currentRound == null) {
      return;
    }

    final index = _turnDrafts.indexWhere((draft) => draft.round == currentRound);
    if (index == -1) {
      return;
    }

    _turnDrafts[index]
      ..selectedChoiceId = choice.id
      ..selectedChoiceText = choice.text;
  }

  String _toMessage(Object error) {
    if (error is GameApiException) {
      return error.message;
    }

    return 'Something broke while generating the scenario. Try again.';
  }
}

class _TurnDraft {
  _TurnDraft({
    required this.round,
    required this.scenario,
    required this.choiceTexts,
  });

  final int round;
  final String scenario;
  final List<String> choiceTexts;
  String? selectedChoiceId;
  String? selectedChoiceText;
}
