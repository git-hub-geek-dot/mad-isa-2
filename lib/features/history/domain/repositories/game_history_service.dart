import 'package:dynamic_scenario_game/features/history/domain/models/game_history_entry.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_run_history.dart';

abstract interface class GameHistoryService {
  Future<void> saveCompletedRun(GameRunHistory run);

  Stream<List<GameHistoryEntry>> watchRecentRuns({int limit = 3});
}
