import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_scenario_game/features/auth/data/firebase_auth_service.dart';
import 'package:dynamic_scenario_game/features/history/data/firestore_game_history_service.dart';
import 'package:dynamic_scenario_game/features/history/domain/repositories/game_history_service.dart';
import 'package:dynamic_scenario_game/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.isConfigured,
    required this.isReady,
    required this.statusLabel,
    this.authService,
    this.historyService,
    this.errorMessage,
  });

  const FirebaseBootstrapResult.disabled({
    required String statusLabel,
    String? errorMessage,
  }) : this(
          isConfigured: false,
          isReady: false,
          statusLabel: statusLabel,
          errorMessage: errorMessage,
        );

  final bool isConfigured;
  final bool isReady;
  final String statusLabel;
  final FirebaseAuthService? authService;
  final GameHistoryService? historyService;
  final String? errorMessage;
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<FirebaseBootstrapResult> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatformOrNull;
    if (options == null) {
      return const FirebaseBootstrapResult.disabled(
        statusLabel: 'Firebase not configured',
      );
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }

      final authService = FirebaseAuthService.instance;
      final historyService = FirestoreGameHistoryService(
        firestore: FirebaseFirestore.instance,
        authService: authService,
      );

      return FirebaseBootstrapResult(
        isConfigured: true,
        isReady: true,
        statusLabel: 'Firebase ready',
        authService: authService,
        historyService: historyService,
      );
    } catch (error) {
      return FirebaseBootstrapResult(
        isConfigured: true,
        isReady: false,
        statusLabel: 'Firebase unavailable',
        errorMessage: error.toString(),
      );
    }
  }
}
