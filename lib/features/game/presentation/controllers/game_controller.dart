import 'package:dynamic_scenario_game/core/config/app_config.dart';
import 'package:dynamic_scenario_game/core/network/game_api_exception.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:dynamic_scenario_game/features/game/domain/repositories/game_repository.dart';
import 'package:flutter/foundation.dart';

enum GameStage {
  idle,
  starting,
  awaitingChoice,
  submittingChoice,
  completed,
}

class GameController extends ChangeNotifier {
  GameController({required GameRepository repository})
      : _repository = repository;

  final GameRepository _repository;

  GameStage _stage = GameStage.idle;
  GameStage get stage => _stage;

  GameSession? _session;
  GameSession? get session => _session;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GameCategory? _lastCategory;
  GameCategory? get lastCategory => _lastCategory;

  bool get isBusy =>
      _stage == GameStage.starting || _stage == GameStage.submittingChoice;

  Future<void> startGame(GameCategory category) async {
    if (isBusy) {
      return;
    }

    _lastCategory = category;
    _errorMessage = null;
    _session = null;
    _stage = GameStage.starting;
    notifyListeners();

    try {
      final nextSession = await _repository.startGame(
        category: category,
        maxRounds: AppConfig.defaultRounds,
      );
      _session = nextSession;
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
    notifyListeners();

    try {
      final nextSession = await _repository.continueGame(
        session: currentSession,
        choice: choice,
      );
      _session = nextSession;
      _stage = nextSession.isFinal
          ? GameStage.completed
          : GameStage.awaitingChoice;
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
    _stage = GameStage.idle;
    notifyListeners();
  }

  String _toMessage(Object error) {
    if (error is GameApiException) {
      return error.message;
    }

    return 'Something broke while generating the scenario. Try again.';
  }
}
