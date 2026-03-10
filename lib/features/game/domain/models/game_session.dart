import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';

class GameSession {
  const GameSession({
    required this.sessionId,
    required this.categoryId,
    required this.round,
    required this.maxRounds,
    required this.scenario,
    required this.choices,
    required this.isFinal,
    this.endingTitle,
    this.roastLine,
  });

  final String sessionId;
  final String categoryId;
  final int round;
  final int maxRounds;
  final String scenario;
  final List<ChoiceOption> choices;
  final bool isFinal;
  final String? endingTitle;
  final String? roastLine;

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>? ?? const [];

    return GameSession(
      sessionId: json['sessionId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      round: json['round'] as int? ?? 1,
      maxRounds: json['maxRounds'] as int? ?? 4,
      scenario: json['scenario'] as String? ?? '',
      choices: choices
          .map((item) => ChoiceOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      isFinal: json['isFinal'] as bool? ?? false,
      endingTitle: json['endingTitle'] as String?,
      roastLine: json['roastLine'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'categoryId': categoryId,
      'round': round,
      'maxRounds': maxRounds,
      'scenario': scenario,
      'choices': choices.map((choice) => choice.toJson()).toList(),
      'isFinal': isFinal,
      'endingTitle': endingTitle,
      'roastLine': roastLine,
    };
  }
}
