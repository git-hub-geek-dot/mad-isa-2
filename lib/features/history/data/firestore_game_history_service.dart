import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_scenario_game/features/auth/data/firebase_auth_service.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_history_entry.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_run_history.dart';
import 'package:dynamic_scenario_game/features/history/domain/repositories/game_history_service.dart';

class FirestoreGameHistoryService implements GameHistoryService {
  FirestoreGameHistoryService({
    required FirebaseFirestore firestore,
    required FirebaseAuthService authService,
  })  : _firestore = firestore,
        _authService = authService;

  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  @override
  Future<void> saveCompletedRun(GameRunHistory run) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return;
    }

    final document = _firestore
        .collection('users')
        .doc(userId)
        .collection('game_history')
        .doc(run.sessionId);

    await document.set({
      'sessionId': run.sessionId,
      'categoryId': run.categoryId,
      'categoryTitle': run.categoryTitle,
      'roundsPlayed': run.roundsPlayed,
      'completedAt': Timestamp.fromDate(run.completedAt),
      'endingTitle': run.endingTitle,
      'roastLine': run.roastLine,
      'endingScenario': run.endingScenario,
      'turns': run.turns.map((turn) => turn.toJson()).toList(),
      'userId': userId,
    });
  }

  @override
  Stream<List<GameHistoryEntry>> watchRecentRuns({int limit = 3}) {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return const Stream<List<GameHistoryEntry>>.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('game_history')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => GameHistoryEntry(
                  id: doc.id,
                  categoryTitle: doc.data()['categoryTitle'] as String? ?? '',
                  endingTitle: doc.data()['endingTitle'] as String? ?? '',
                  roastLine: doc.data()['roastLine'] as String? ?? '',
                  roundsPlayed: doc.data()['roundsPlayed'] as int? ?? 0,
                  completedAt:
                      (doc.data()['completedAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0),
                ),
              )
              .toList(),
        );
  }
}
