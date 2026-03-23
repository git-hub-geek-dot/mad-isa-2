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
      'notes': [],
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

  /// Add a new note to a game session
  Future<void> addNote(String sessionId, String noteContent) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final noteId = _firestore.collection('dummy').doc().id;
    final now = DateTime.now();

    final document = _firestore
        .collection('users')
        .doc(userId)
        .collection('game_history')
        .doc(sessionId);

    await document.update({
      'notes': FieldValue.arrayUnion([
        {
          'id': noteId,
          'content': noteContent,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        }
      ])
    });
  }

  /// Update an existing note in a game session
  Future<void> updateNote(
      String sessionId, String noteId, String updatedContent) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final document = _firestore
        .collection('users')
        .doc(userId)
        .collection('game_history')
        .doc(sessionId);

    // Get the current document to update the specific note
    final docSnapshot = await document.get();
    final notes = List<Map<String, dynamic>>.from(
        (docSnapshot.data()?['notes'] as List?)?.cast<Map<String, dynamic>>() ??
            []);

    // Find and update the note
    final noteIndex = notes.indexWhere((note) => note['id'] == noteId);
    if (noteIndex != -1) {
      notes[noteIndex]['content'] = updatedContent;
      notes[noteIndex]['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await document.update({'notes': notes});
    }
  }

  /// Delete a note from a game session
  Future<void> deleteNote(String sessionId, String noteId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final document = _firestore
        .collection('users')
        .doc(userId)
        .collection('game_history')
        .doc(sessionId);

    // Get the current document to remove the specific note
    final docSnapshot = await document.get();
    final notes = List<Map<String, dynamic>>.from(
        (docSnapshot.data()?['notes'] as List?)?.cast<Map<String, dynamic>>() ??
            []);

    // Remove the note
    notes.removeWhere((note) => note['id'] == noteId);
    await document.update({'notes': notes});
  }

  /// Fetch complete game run details by session ID
  @override
  Future<GameRunHistory?> getGameRunDetails(String sessionId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return null;
    }

    try {
      final document = _firestore
          .collection('users')
          .doc(userId)
          .collection('game_history')
          .doc(sessionId);

      final docSnapshot = await document.get();
      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data()!;
      final notesList = (data['notes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      return GameRunHistory(
        sessionId: data['sessionId'] as String,
        categoryId: data['categoryId'] as String,
        categoryTitle: data['categoryTitle'] as String,
        roundsPlayed: data['roundsPlayed'] as int,
        completedAt: (data['completedAt'] as Timestamp).toDate(),
        endingTitle: data['endingTitle'] as String,
        roastLine: data['roastLine'] as String,
        endingScenario: data['endingScenario'] as String,
        turns: ((data['turns'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(
              (turn) => GameTurnHistory(
                round: turn['round'] as int,
                scenario: turn['scenario'] as String,
                choiceTexts: List<String>.from(turn['choiceTexts'] as List),
                selectedChoiceId: turn['selectedChoiceId'] as String?,
                selectedChoiceText: turn['selectedChoiceText'] as String?,
              ),
            )
            .toList(),
        notes: notesList
            .map((note) => GameNote.fromJson(note))
            .toList(),
      );
    } catch (e) {
      return null;
    }
  }
}
