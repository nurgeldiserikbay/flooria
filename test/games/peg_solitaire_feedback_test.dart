import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/peg_solitaire/peg_solitaire_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openPeg(WidgetTester tester, int level, {bool reducedMotion = false}) async {
  final game = GameRegistry.byId('peg_solitaire');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(context,
        GameLaunch(level: level, mode: GamePlayMode.standalone, onComplete: (_) {}))),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

(int, int)? findJump(PegSolitaireEngine engine) {
  for (var source = 0; source < engine.board.length; source++) {
    if (engine.board[source] == 0) continue;
    final sr = source ~/ PegSolitaireEngine.side;
    final sc = source % PegSolitaireEngine.side;
    for (final (dr, dc) in const [(0, 2), (0, -2), (2, 0), (-2, 0)]) {
      final row = sr + dr;
      final col = sc + dc;
      if (row < 0 || col < 0 || row >= 7 || col >= 7) continue;
      final target = row * 7 + col;
      final mid = (sr + dr ~/ 2) * 7 + sc + dc ~/ 2;
      if (PegSolitaireEngine.isValidCell(target) &&
          engine.board[target] == 0 && engine.board[mid] == 1) {
        return (source, target);
      }
    }
  }
  return null;
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Peg Solitaire level $level on $size', (tester) async {
        viewport(tester, size);
        await openPeg(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('peg-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Peg Solitaire explains selection and legal jumps', (tester) async {
    viewport(tester, const Size(390, 844));
    await openPeg(tester, 1);
    final board = find.byKey(const ValueKey('peg-board-state'));
    final engine = PegSolitaireEngine.forLevel(1);
    final jump = findJump(engine);
    expect(jump, isNotNull);
    final (source, target) = jump!;
    final before = engine.pegCount;

    expect(tester.widget<Semantics>(board).properties.label,
      contains('$before pegs remaining'));
    await tester.tap(find.byKey(ValueKey('peg-cell-$source')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('PEG SELECTED'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('peg-cell-$target')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('${before - 1} pegs remaining'));
    expect(find.textContaining('GREAT JUMP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Peg Solitaire respects reduced-motion mode', (tester) async {
    await openPeg(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('peg-cell-24'));
    expect(tester.widget<AnimatedScale>(
      find.descendant(of: cell, matching: find.byType(AnimatedScale)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
