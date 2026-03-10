import 'package:dynamic_scenario_game/app/theme/app_theme.dart';
import 'package:dynamic_scenario_game/core/config/app_config.dart';
import 'package:dynamic_scenario_game/core/network/scenario_api_client.dart';
import 'package:dynamic_scenario_game/features/game/data/game_repository_impl.dart';
import 'package:dynamic_scenario_game/features/game/data/mock_scenario_api_client.dart';
import 'package:dynamic_scenario_game/features/game/data/remote_scenario_api_client.dart';
import 'package:dynamic_scenario_game/features/game/presentation/controllers/game_controller.dart';
import 'package:dynamic_scenario_game/features/game/presentation/screens/game_screen.dart';
import 'package:dynamic_scenario_game/features/game/presentation/screens/home_screen.dart';
import 'package:dynamic_scenario_game/features/game/presentation/screens/result_screen.dart';
import 'package:flutter/material.dart';

class AiScenarioGameApp extends StatefulWidget {
  const AiScenarioGameApp({super.key});

  @override
  State<AiScenarioGameApp> createState() => _AiScenarioGameAppState();
}

class _AiScenarioGameAppState extends State<AiScenarioGameApp> {
  late final GameController _controller;
  late final bool _usesMockApi;

  @override
  void initState() {
    super.initState();
    final apiClient = _buildApiClient();
    _controller = GameController(
      repository: GameRepositoryImpl(apiClient: apiClient),
    );
  }

  ScenarioApiClient _buildApiClient() {
    final hasRemoteConfig = AppConfig.apiBaseUrl.isNotEmpty;
    final useRemote = !AppConfig.useMockApi && hasRemoteConfig;
    _usesMockApi = !useRemote;

    if (useRemote) {
      return RemoteScenarioApiClient(
        baseUrl: AppConfig.apiBaseUrl,
        apiKey: AppConfig.apiKey,
      );
    }

    return MockScenarioApiClient();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Scenario Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final session = _controller.session;

          if (session?.isFinal ?? false) {
            return ResultScreen(
              session: session!,
              usesMockApi: _usesMockApi,
              onPlayAgain: _controller.playAgain,
              onBackHome: _controller.backToHome,
            );
          }

          if (session != null || _controller.stage == GameStage.starting) {
            return GameScreen(
              controller: _controller,
              usesMockApi: _usesMockApi,
            );
          }

          return HomeScreen(
            controller: _controller,
            usesMockApi: _usesMockApi,
          );
        },
      ),
    );
  }
}
