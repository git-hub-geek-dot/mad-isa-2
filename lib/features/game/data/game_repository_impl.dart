import 'package:dynamic_scenario_game/core/network/scenario_api_client.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:dynamic_scenario_game/features/game/domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl({required ScenarioApiClient apiClient})
      : _apiClient = apiClient;

  final ScenarioApiClient _apiClient;

  @override
  Future<GameSession> startGame({
    required GameCategory category,
    required int maxRounds,
  }) {
    return _apiClient.startGame(category: category, maxRounds: maxRounds);
  }

  @override
  Future<GameSession> continueGame({
    required GameSession session,
    required ChoiceOption choice,
  }) {
    return _apiClient.continueGame(session: session, choice: choice);
  }
}
