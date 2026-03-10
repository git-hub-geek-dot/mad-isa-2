import 'package:dynamic_scenario_game/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders home screen title', (tester) async {
    await tester.pumpWidget(const AiScenarioGameApp());
    await tester.pumpAndSettle();

    expect(
      find.text('AI-Based Dynamic Scenario Simulation Game'),
      findsOneWidget,
    );
    expect(find.text('Play Scenario'), findsOneWidget);
  });
}
