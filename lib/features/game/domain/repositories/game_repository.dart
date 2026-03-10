import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';

abstract interface class GameRepository {
  Future<GameSession> startGame({
    required GameCategory category,
    required int maxRounds,
  });

  Future<GameSession> continueGame({
    required GameSession session,
    required ChoiceOption choice,
  });
}
