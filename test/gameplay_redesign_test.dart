import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/ui/game_kit.dart';

void main() {
  const palette = GamePalette(
    ground: Color(0xFFF5F8FF),
    surface: Colors.white,
    ink: Color(0xFF263252),
    muted: Color(0xFF64718C),
    accent: Color(0xFF6655DD),
    edge: Color(0xFFDCE1F0),
  );

  testWidgets('redesigned gameplay stage retains game and level content',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GameScaffold(
        palette: palette,
        title: 'Pattern Repeat',
        level: 7,
        child: Center(child: Text('Playable board')),
      ),
    ));

    expect(find.text('Pattern Repeat'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Playable board'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-back')), findsOneWidget);
  });

  testWidgets('gameplay header accepts module actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScaffold(
        palette: palette,
        title: 'Synapse Link',
        level: 1,
        actions: const [Icon(Icons.refresh_rounded)],
        child: const SizedBox.expand(),
      ),
    ));

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
