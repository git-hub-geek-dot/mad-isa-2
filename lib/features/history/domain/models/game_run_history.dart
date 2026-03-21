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
