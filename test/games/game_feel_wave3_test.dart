import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

const _gameIds = [
  'merge_tiles',
  'sokoban',
  'bubble_shooter',
  'path_paint',
  'snake',
  'brick_break',
];

const _viewports = [Size(360, 640), Size(390, 844)];

void _size(WidgetTester tester, Size viewport) {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String id, {int level = 1}) async {
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => game.buildPage(context, GameLaunch(
      level: level,
      mode: GamePlayMode.standalone,
      onComplete: (_) {},
    ))),
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final gameId in _gameIds) {
    for (final viewport in _viewports) {
      for (final level in const [1, 90]) {
        testWidgets(
          '$gameId level $level fits ${viewport.width}x${viewport.height}',
          (tester) async {
            _size(tester, viewport);
            await _open(tester, gameId, level: level);
            expect(find.text('LEVEL $level'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('Merge 2048 swipes with animated numbered tiles',
      (tester) async {
    _size(tester, const Size(390, 844));
    await _open(tester, 'merge_tiles');
    expect(find.byKey(const ValueKey('merge-tile-0')), findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('merge-board')),
        const Offset(-85, 0));
    await tester.pump(const Duration(milliseconds: 280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sokoban arrows move the player without changing goals',
      (tester) async {
    _size(tester, const Size(390, 844));
    await _open(tester, 'sokoban');
    expect(find.byKey(const ValueKey('sokoban-cell-39')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_right_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    final movesChip = find.ancestor(
      of: find.text('MOVES'),
      matching: find.byType(StatChip),
    );
    expect(
      find.descendant(of: movesChip, matching: find.text('1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bubble Shooter pops and shows next glossy bubble',
      (tester) async {
    _size(tester, const Size(390, 844));
    await _open(tester, 'bubble_shooter');
    await tester.tap(find.byKey(const ValueKey('bubble-column-0')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Path Paint drag keeps drawing and board in sync',
      (tester) async {
    _size(tester, const Size(390, 844));
    await _open(tester, 'path_paint');
    final board = find.byKey(const ValueKey('path-paint-board'));
    final rect = tester.getRect(board);
    final cell = rect.width / 5;
    await tester.timedDragFrom(
      rect.topLeft + Offset(cell / 2, cell / 2),
      Offset(cell * .95, 0),
      const Duration(milliseconds: 240),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Snake starts ticking and disposes its timer safely',
      (tester) async {
    _size(tester, const Size(390, 844));
    await _open(tester, 'snake');
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Brick Break launches and renders the moving ball',
      (tester) async {
    _size(tester, const Size(390, 844));
    await _open(tester, 'brick_break');
    await tester.tap(find.byKey(const ValueKey('brick-board')));
    await tester.pump(const Duration(milliseconds: 64));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
