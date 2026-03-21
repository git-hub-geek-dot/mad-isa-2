import 'package:dynamic_scenario_game/core/firebase/firebase_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_scenario_game/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseBootstrap = await FirebaseBootstrap.initialize();
  runApp(AiScenarioGameApp(firebaseBootstrap: firebaseBootstrap));
}
