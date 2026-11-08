import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/tetris/tetris_engine.dart';
import 'package:flooria/games/tetris/tetris_page.dart';

void main() {
  test('ghost piece marks a legal hard-drop landing', () {
    final engine = TetrisEngine.forLevel(2, seed: 921);
    final active = engine.activeCells().toSet();
    final ghost = engine.ghostCells().toSet();

    expect(active, hasLength(4));
    expect(ghost, hasLength(4));
    expect(ghost.intersection(active), isEmpty);
    expect(engine.act(TetrisAction.hardDrop), TetrisTick.locked);
    expect(ghost.every((cell) => engine.board[cell] != 0), isTrue);
  });

  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Tetris controls and ghost board fit ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: TetrisPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        )),
      ));

      expect(find.byKey(const ValueKey('tetris-board')), findsOneWidget);
      expect(find.byTooltip('Left'), findsOneWidget);
      expect(find.byTooltip('Hard drop'), findsOneWidget);
      await tester.longPress(find.byTooltip('Left'),
          duration: const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 130));
      expect(tester.takeException(), isNull);
    });
  }
}
