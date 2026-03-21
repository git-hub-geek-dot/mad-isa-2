class GameHistoryEntry {
  const GameHistoryEntry({
    required this.id,
    required this.categoryTitle,
    required this.endingTitle,
    required this.roastLine,
    required this.roundsPlayed,
    required this.completedAt,
  });

  final String id;
  final String categoryTitle;
  final String endingTitle;
  final String roastLine;
  final int roundsPlayed;
  final DateTime completedAt;
}
