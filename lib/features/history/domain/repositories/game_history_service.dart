import 'package:dynamic_scenario_game/features/history/domain/models/game_history_entry.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_run_history.dart';

abstract interface class GameHistoryService {
  Future<void> saveCompletedRun(GameRunHistory run);

  Stream<List<GameHistoryEntry>> watchRecentRuns({int limit = 3});

  Future<void> addNote(String sessionId, String noteContent);

  Future<void> updateNote(
      String sessionId, String noteId, String updatedContent);

  Future<void> deleteNote(String sessionId, String noteId);

  Future<GameRunHistory?> getGameRunDetails(String sessionId);
}
