class GameRunHistory {
  const GameRunHistory({
    required this.sessionId,
    required this.categoryId,
    required this.categoryTitle,
    required this.roundsPlayed,
    required this.completedAt,
    required this.endingTitle,
    required this.roastLine,
    required this.endingScenario,
    required this.turns,
    this.notes = const [],
  });

  final String sessionId;
  final String categoryId;
  final String categoryTitle;
  final int roundsPlayed;
  final DateTime completedAt;
  final String endingTitle;
  final String roastLine;
  final String endingScenario;
  final List<GameTurnHistory> turns;
  final List<GameNote> notes;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'categoryId': categoryId,
      'categoryTitle': categoryTitle,
      'roundsPlayed': roundsPlayed,
      'completedAt': completedAt,
      'endingTitle': endingTitle,
      'roastLine': roastLine,
      'endingScenario': endingScenario,
      'turns': turns.map((turn) => turn.toJson()).toList(),
      'notes': notes.map((note) => note.toJson()).toList(),
    };
  }
}

class GameTurnHistory {
  const GameTurnHistory({
    required this.round,
    required this.scenario,
    required this.choiceTexts,
    this.selectedChoiceId,
    this.selectedChoiceText,
  });

  final int round;
  final String scenario;
  final List<String> choiceTexts;
  final String? selectedChoiceId;
  final String? selectedChoiceText;

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'scenario': scenario,
      'choiceTexts': choiceTexts,
      'selectedChoiceId': selectedChoiceId,
      'selectedChoiceText': selectedChoiceText,
    };
  }
}

class GameNote {
  const GameNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory GameNote.fromJson(Map<String, dynamic> json) {
    return GameNote(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
