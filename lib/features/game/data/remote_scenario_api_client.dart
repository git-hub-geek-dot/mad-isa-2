import 'dart:convert';

import 'package:dynamic_scenario_game/core/network/game_api_exception.dart';
import 'package:dynamic_scenario_game/core/network/scenario_api_client.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';
import 'package:http/http.dart' as http;

class RemoteScenarioApiClient implements ScenarioApiClient {
  RemoteScenarioApiClient({
    required this.baseUrl,
    this.apiKey = '',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _httpClient;

  @override
  Future<GameSession> startGame({
    required GameCategory category,
    required int maxRounds,
  }) {
    return _post('/game/start', {
      'theme': category.id,
      'tone': 'dark_comedy',
      'maxRounds': maxRounds,
      'promptHint': category.promptHint,
    });
  }

  @override
  Future<GameSession> continueGame({
    required GameSession session,
    required ChoiceOption choice,
  }) {
    return _post('/game/continue', {
      'sessionId': session.sessionId,
      'selectedChoiceId': choice.id,
      'selectedChoiceText': choice.text,
    });
  }

  Future<GameSession> _post(String path, Map<String, dynamic> payload) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(payload),
      );

      final body = response.body;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GameApiException(
          _extractErrorMessage(body),
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const GameApiException('Expected a JSON object response.');
      }

      return GameSession.fromJson(decoded);
    } on http.ClientException {
      throw const GameApiException(
        'Network error. Check API reachability and try again.',
      );
    } on FormatException {
      throw const GameApiException(
        'Malformed API response. Expected JSON matching the game session shape.',
      );
    }
  }

  String _extractErrorMessage(String body) {
    if (body.isEmpty) {
      return 'Request failed.';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final nestedError = decoded['error'];
        if (nestedError is Map<String, dynamic>) {
          final message = nestedError['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }

        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      // Fall back to the raw response body.
    }

    return body;
  }
}
