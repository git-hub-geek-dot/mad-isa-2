import 'dart:async';
import 'dart:math';

import 'package:dynamic_scenario_game/core/network/scenario_api_client.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/choice_option.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_category.dart';
import 'package:dynamic_scenario_game/features/game/domain/models/game_session.dart';

class MockScenarioApiClient implements ScenarioApiClient {
  MockScenarioApiClient();

  final Map<String, _MockSessionState> _sessions = {};
  final Random _random = Random();

  static final Map<String, _MockCategoryScript> _scripts = {
    'relationship_chaos': _MockCategoryScript(
      rounds: [
        _RoundBeat(
          scenario:
              'Your partner posts a cryptic quote about trust, then leaves your message on read while liking a gym selfie from someone named Blaze. The chat is silent, your ego is loud, and your best friend is already drafting toxic advice. You have about twenty seconds before this becomes a status update with casualties.',
          choices: [
              'Reply with "interesting" and let dread do the heavy lifting.',
            'Send a calm paragraph that is secretly a legal threat.',
            'Post your own mystery quote and pretend it is growth.',
          ],
        ),
        _RoundBeat(
          scenario:
              'The situation mutates when Blaze comments "legend" under your partner\'s post and your cousin sends a screenshot with eight question marks. The room now has the energy of a reality show reunion filmed in a microwave. Everybody wants clarity, which is unfortunate because clarity left the building two bad decisions ago.',
          choices: [
            'Call your partner and open with fake maturity.',
            'Text Blaze directly like a detective with no jurisdiction.',
            'Ask the cousin to leak misinformation for strategic balance.',
          ],
        ),
        _RoundBeat(
          scenario:
              'Your partner finally replies with "wow" and nothing else, which is the emotional equivalent of a chair being thrown off-camera. A mutual friend volunteers to mediate despite loving chaos more than oxygen. The conversation is now one screenshot away from becoming a family dinner topic nobody survives with dignity.',
          choices: [
            'Accept mediation and weaponize politeness.',
            'Drop an audio note that sounds calm but scary.',
            'Pretend your phone died and blame cosmic timing.',
          ],
        ),
        _RoundBeat(
          scenario:
              'A final twist arrives when the cryptic quote turns out to be copied from a candle brand, but by now three people have chosen sides and one aunt is praying in the group chat. You can still exit with fragments of pride, although that ship is sailing on a puddle of screenshots and dramatic punctuation.',
          choices: [
            'Confess you overreacted and pivot into self-awareness.',
            'Insist this was a social experiment on loyalty.',
            'Break the tension with a joke so reckless it may reset society.',
          ],
        ),
      ],
      endingTitle: 'Mission Complete: Romance Containment',
      roastTemplates: [
        'You survived, but only because everyone else got tired first.',
        'Your emotional strategy had the elegance of a shopping cart with one broken wheel.',
        'You turned miscommunication into performance art, which is impressive and deeply concerning.',
      ],
    ),
    'friendship_meltdown': _MockCategoryScript(
      rounds: [
        _RoundBeat(
          scenario:
              'Your group chat suddenly renames itself "Core Four" and you notice there are now only three people typing. A suspicious inside joke appears, followed by a deleted message and a thumbs-up from the friend who usually starts mess then naps. The betrayal is still theoretical, but your imagination is already writing a courtroom drama.',
          choices: [
              'Send "did I miss something?" with terrifying restraint.',
            'Post a meme about fake friends and let chaos self-identify.',
            'Open a side chat with the weakest link first.',
          ],
        ),
        _RoundBeat(
          scenario:
              'One friend claims the rename was an accident, which would be believable if the new group photo were not a cropped picture without your face in it. Another friend says everyone is "just busy," the universal anthem of organized nonsense. You can smell dishonesty and energy drinks through the phone.',
          choices: [
            'Demand a voice call and keep receipts open.',
            'Pretend you do not care while caring professionally.',
            'Recruit an outside friend as an unofficial analyst.',
          ],
        ),
        _RoundBeat(
          scenario:
              'The analyst reports that two friends were planning a surprise hangout, except the surprise appears to be your absence. Meanwhile, one guilty party keeps reacting to messages with hearts, which somehow feels worse than open violence. The social ecosystem is fragile, silly, and moments away from a dramatic extinction event.',
          choices: [
            'Crash the hangout with bakery peace offerings.',
            'Expose the evidence and let the silence cook.',
            'Turn the whole thing into a fake podcast episode.',
          ],
        ),
        _RoundBeat(
          scenario:
              'The truth finally spills: the plan was half surprise party, half avoidance of your habit of turning board games into military campaigns. This is both flattering and devastating. The chat waits for your response like villagers watching someone approach a cursed lever in a thunderstorm.',
          choices: [
            'Apologize for the competitive energy and reclaim the room.',
            'Negotiate friendship terms like a tiny union boss.',
            'Reply with a dramatic "understood" and vanish for one minute.',
          ],
        ),
      ],
      endingTitle: 'Mission Complete: Group Chat Diplomacy',
      roastTemplates: [
        'You restored the friendship, but your reputation now arrives with a caution label.',
        'Your communication style remains ninety percent instinct and ten percent accidental theater.',
        'Congratulations on winning an argument nobody should have needed to host.',
      ],
    ),
    'daily_absurdity': _MockCategoryScript(
      rounds: [
        _RoundBeat(
          scenario:
              'You order one iced coffee before work, but the barista writes "good luck" on the cup and hands you a drink the color of unresolved tax issues. Five minutes later your manager asks for an urgent meeting, your shoe makes a noise like a dying accordion, and the universe feels personally entertained.',
          choices: [
            'Drink the coffee and trust pure chaos as a lifestyle.',
            'Throw it away and start the day suspicious but hydrated.',
            'Take a photo first in case this becomes evidence.',
          ],
        ),
        _RoundBeat(
          scenario:
              'The urgent meeting turns out to be about a printer jam that somehow has your name on it, despite you never touching printers without emotional support. At the same time, your landlord texts "call me" and a stranger compliments your "bold" sock choice. Disaster is now crowd-sourced and weirdly confident.',
          choices: [
            'Fix the printer aggressively and earn a legend arc.',
            'Blame Mercury retrograde with executive certainty.',
            'Handle the landlord first and let office folklore grow.',
          ],
        ),
        _RoundBeat(
          scenario:
              'You discover the landlord only wanted permission to repaint the hallway, but by then your boss has heard a version of the printer story where you challenged technology to a duel. Meanwhile, the suspicious coffee has kicked in and your thoughts are sprinting like they owe rent.',
          choices: [
            'Lean into competence and solve everything too fast.',
            'Take a tactical bathroom break and reset your soul.',
            'Start narrating your day like a nature documentary.',
          ],
        ),
        _RoundBeat(
          scenario:
              'The printer works, the hallway becomes beige, and the sock stranger turns out to be a recruiter who thinks you have "presence." Your absurd day is somehow converting into opportunity, which feels illegal. One final decision stands between you and a clean escape from this aggressively unserious timeline.',
          choices: [
            'Accept the weird compliment and walk out composed.',
            'Ask for details and accidentally create a second subplot.',
            'Go home immediately before destiny notices you again.',
          ],
        ),
      ],
      endingTitle: 'Mission Complete: Ordinary Day Survival',
      roastTemplates: [
        'You made it through the day with the confidence of someone who confuses momentum for planning.',
        'Your crisis management style is basically jazz, and somehow it kept working.',
        'You treated randomness like a co-worker and now it respects you too much.',
      ],
    ),
  };

  @override
  Future<GameSession> startGame({
    required GameCategory category,
    required int maxRounds,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: 650 + _random.nextInt(450)),
    );

    final script = _scripts[category.id] ?? _scripts.values.first;
    final safeRounds = max(1, min(maxRounds, script.rounds.length));
    final sessionId =
        '${category.id}-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(999)}';
    final state = _MockSessionState(
      sessionId: sessionId,
      category: category,
      script: script,
      maxRounds: safeRounds,
    );
    _sessions[sessionId] = state;
    return _buildRoundSession(state);
  }

  @override
  Future<GameSession> continueGame({
    required GameSession session,
    required ChoiceOption choice,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: 700 + _random.nextInt(500)),
    );

    final state = _sessions[session.sessionId];
    if (state == null) {
      throw StateError('Session expired. Start a new run.');
    }

    state.choiceHistory.add(choice.text);

    if (state.round >= state.maxRounds) {
      _sessions.remove(session.sessionId);
      return _buildFinalSession(state);
    }

    state.round += 1;
    return _buildRoundSession(state);
  }

  GameSession _buildRoundSession(_MockSessionState state) {
    final beat = state.script.rounds[state.round - 1];
    final callback = state.choiceHistory.isEmpty
        ? 'Nobody has messed this up yet, which feels temporary.'
        : 'Your last move was "${state.choiceHistory.last}", so the tension now has a body count and a ringtone.';
    final scenario = '${beat.scenario} $callback';

    return GameSession(
      sessionId: state.sessionId,
      categoryId: state.category.id,
      round: state.round,
      maxRounds: state.maxRounds,
      scenario: scenario,
      choices: [
        for (var index = 0; index < beat.choices.length; index += 1)
          ChoiceOption(
            id: 'round_${state.round}_choice_$index',
            text: beat.choices[index],
          ),
      ],
      isFinal: false,
    );
  }

  GameSession _buildFinalSession(_MockSessionState state) {
    final lastChoice = state.choiceHistory.isEmpty
        ? 'doing absolutely nothing'
        : state.choiceHistory.last.toLowerCase();
    final roast = state.script.roastTemplates[
        _random.nextInt(state.script.roastTemplates.length)];

    return GameSession(
      sessionId: state.sessionId,
      categoryId: state.category.id,
      round: state.maxRounds,
      maxRounds: state.maxRounds,
      scenario:
          'The dust settles, nobody learned enough, and the timeline closes with a suspicious amount of confidence.',
      choices: const [],
      isFinal: true,
      endingTitle: state.script.endingTitle,
      roastLine:
          '$roast Choosing "$lastChoice" as the final move was bold in the way loose shopping-cart wheels are bold.',
    );
  }
}

class _MockSessionState {
  _MockSessionState({
    required this.sessionId,
    required this.category,
    required this.script,
    required this.maxRounds,
  });

  final String sessionId;
  final GameCategory category;
  final _MockCategoryScript script;
  final int maxRounds;
  final List<String> choiceHistory = [];

  int round = 1;
}

class _MockCategoryScript {
  const _MockCategoryScript({
    required this.rounds,
    required this.endingTitle,
    required this.roastTemplates,
  });

  final List<_RoundBeat> rounds;
  final String endingTitle;
  final List<String> roastTemplates;
}

class _RoundBeat {
  const _RoundBeat({
    required this.scenario,
    required this.choices,
  });

  final String scenario;
  final List<String> choices;
}
