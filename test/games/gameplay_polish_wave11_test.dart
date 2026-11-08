import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/clone_shift/clone_shift_engine.dart';
import 'package:flooria/games/peg_solitaire/peg_solitaire_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String id, {
  int level = 1,
  bool reduceMotion = false,
}) async {
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Builder(builder: (context) => game.buildPage(
        context, GameLaunch(
          level: level,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        ),
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 250));
}

(int, int)? _legalJump(PegSolitaireEngine engine) {
  for (var source = 0; source < engine.board.length; source++) {
    if (!PegSolitaireEngine.isValidCell(source) ||
        engine.board[source] != 1) {
      continue;
    }
    final r = source ~/ PegSolitaireEngine.side;
    final c = source % PegSolitaireEngine.side;
    for (final (dr, dc) in const [
      (-2, 0), (2, 0), (0, -2), (0, 2),
    ]) {
      final tr = r + dr;
      final tc = c + dc;
      if (tr < 0 || tc < 0 ||
          tr >= PegSolitaireEngine.side ||
          tc >= PegSolitaireEngine.side) {
        continue;
      }
      final dest = tr * PegSolitaireEngine.side + tc;
      final mid = (r + dr ~/ 2) * PegSolitaireEngine.side +
          c + dc ~/ 2;
      if (PegSolitaireEngine.isValidCell(dest) &&
          engine.board[dest] == 0 && engine.board[mid] == 1) {
        return (source, dest);
      }
    }
  }
  return null;
}

void main() {
  for (final id in const ['peg_solitaire', 'clone_shift']) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level at ${size.width}x${size.height}',
            (tester) async {
          _viewport(tester, size);
          await _open(tester, id, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 280));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Peg Solitaire highlights legal landing and clears selection',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'peg_solitaire');
    final engine = PegSolitaireEngine.forLevel(1);
    final jump = _legalJump(engine);
    expect(jump, isNotNull);
    final (source, destination) = jump!;
    final sourceCell = find.byKey(ValueKey('peg-cell-$source'));
    final destinationCell = find.byKey(ValueKey('peg-cell-$destination'));

    await tester.tap(sourceCell);
    await tester.pump(const Duration(milliseconds: 210));
    expect(tester.widget<Semantics>(sourceCell).properties.label,
        contains('selected'));
    expect(tester.widget<Semantics>(destinationCell).properties.label,
        contains('legal landing'));

    // Deselecting the same peg is an engine "ignored" action, but the
    // selected state must still repaint.
    await tester.tap(sourceCell);
    await tester.pump(const Duration(milliseconds: 210));
    expect(tester.widget<Semantics>(sourceCell).properties.label,
        isNot(contains('selected')));
    expect(tester.widget<Semantics>(destinationCell).properties.label,
        isNot(contains('legal landing')));

    await tester.tap(sourceCell);
    await tester.pump(const Duration(milliseconds: 190));
    await tester.tap(destinationCell);
    await tester.pump(const Duration(milliseconds: 260));
    expect(tester.widget<Semantics>(sourceCell).properties.label,
        contains('empty hole'));
    expect(tester.widget<Semantics>(destinationCell).properties.label,
        contains('peg'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clone Shift shows both avatars moving together',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'clone_shift');
    final engine = CloneShiftEngine.forLevel(1);
    expect(engine.positions, [20, 24]);
    expect(find.byKey(const ValueKey('clone-avatar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('clone-avatar-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('clone-board')), findsOneWidget);

    await tester.tap(find.byTooltip('Move up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('clone-cell-15')),
    ).properties.label, contains('explorer 1'));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('clone-cell-19')),
    ).properties.label, contains('explorer 2'));
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both games honour reduced motion', (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'peg_solitaire', reduceMotion: true);
    final peg = find.byKey(const ValueKey('peg-cell-24'));
    final pegScale = tester.widget<AnimatedScale>(
      find.descendant(of: peg, matching: find.byType(AnimatedScale)),
    );
    expect(pegScale.duration, Duration.zero);

    await _open(tester, 'clone_shift', reduceMotion: true);
    for (var i = 0; i < 2; i++) {
      final avatar = tester.widget<AnimatedPositioned>(
        find.byKey(ValueKey('clone-avatar-$i')),
      );
      expect(avatar.duration, Duration.zero);
    }
    expect(tester.takeException(), isNull);
  });
}
