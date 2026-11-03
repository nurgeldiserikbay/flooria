import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/hue_sort/hue_sort_engine.dart';
import 'package:flooria/games/ice_slide/ice_slide_engine.dart';
import 'package:flooria/games/shape_turn/shape_turn_engine.dart';
import 'package:flooria/games/signal_guard/signal_guard_engine.dart';
import 'package:flooria/games/synapse_link/synapse_link_engine.dart';
import 'package:flooria/games/target_sum/target_sum_engine.dart';

import 'ice_slide_engine_test.dart' show shortestRoute;
import 'target_sum_engine_test.dart' show findSolution;

const _ids = ['hue_sort', 'synapse_link', 'target_sum', 'ice_slide',
  'shape_turn', 'signal_guard'];

Future<void> _view(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<List<GameResult>> _open(WidgetTester tester, String id, int level,
    {GamePlayMode mode = GamePlayMode.neuron}) async {
  final results = <GameResult>[];
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => game.buildPage(context, GameLaunch(
      level: level,
      mode: mode,
      onComplete: results.add,
    ))),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  return results;
}

void main() {
  for (final id in _ids) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level fits ${size.width}x${size.height}',
            (tester) async {
          await _view(tester, size);
          final results = await _open(tester, id, level);
          expect(tester.takeException(), isNull);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(results, isEmpty);
        });
      }
    }
  }

  testWidgets('Synapse Link is won by turning tiles home', (tester) async {
    await _view(tester, const Size(390, 844));
    final results = await _open(tester, 'synapse_link', 4);
    final engine = SynapseLinkEngine.forLevel(4);
    for (var i = 0; i < engine.cellCount; i++) {
      while (engine.maskAt(i) != engine.solution[i] && !engine.isCompleted) {
        engine.rotate(i);
        await tester.tap(find.byKey(ValueKey('synapse-tile-$i')));
        await tester.pump(const Duration(milliseconds: 40));
      }
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('level-clear')), findsOneWidget);
    expect(find.text('NEXT LEVEL'), findsOneWidget);
    expect(results.single.level, 4);
    expect(results.single.metrics['logic'], 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ice Slide is won with the arrow pad', (tester) async {
    await _view(tester, const Size(360, 640));
    final results = await _open(tester, 'ice_slide', 2);
    final route = shortestRoute(IceSlideEngine.forLevel(2))!;
    for (final direction in route) {
      await tester.tap(find.byKey(ValueKey('ice-arrow-${direction.name}')));
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byKey(const ValueKey('level-clear')), findsOneWidget);
    expect(results.single.metrics['planning'], 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ice Slide also follows swipes', (tester) async {
    await _view(tester, const Size(390, 844));
    await _open(tester, 'ice_slide', 2);
    final engine = IceSlideEngine.forLevel(2);
    final direction = SlideDirection.values.firstWhere(
      (d) => engine.slideLength(d) > 0);
    final offset = switch (direction) {
      SlideDirection.up => const Offset(0, -80),
      SlideDirection.right => const Offset(80, 0),
      SlideDirection.down => const Offset(0, 80),
      SlideDirection.left => const Offset(-80, 0),
    };
    await tester.drag(find.byKey(const ValueKey('ice-board')), offset);
    await tester.pump(const Duration(milliseconds: 500));
    final moves = tester.widget<Text>(find.byKey(const ValueKey('ice-moves')));
    expect(moves.data, '1');
  });

  testWidgets('Hue Sort is won by swapping tiles home and moves on',
      (tester) async {
    await _view(tester, const Size(390, 844));
    final results = await _open(tester, 'hue_sort', 1,
      mode: GamePlayMode.standalone);
    final engine = HueSortEngine.forLevel(1);
    for (var p = 0; p < engine.cellCount; p++) {
      while (engine.tileAt(p) != p) {
        final q = engine.tileAt(p);
        engine.swap(p, q);
        await tester.tap(find.byKey(ValueKey('hue-cell-$p')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byKey(ValueKey('hue-cell-$q')));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('level-clear')), findsOneWidget);
    expect(results.single.metrics['perception'], 100);

    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LEVEL 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-clear')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Target Sum is won by filling the right totals', (tester) async {
    await _view(tester, const Size(360, 640));
    final results = await _open(tester, 'target_sum', 3);
    final engine = TargetSumEngine.forLevel(3);
    for (var round = 0; round < engine.rounds.length; round++) {
      for (final tile in findSolution(engine.rounds[round])) {
        await tester.tap(find.byKey(ValueKey('sum-tile-$round-$tile')));
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.byKey(const ValueKey('level-clear')), findsOneWidget);
    expect(results.single.metrics['math'], 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shape Turn is won by picking the turned shape', (tester) async {
    await _view(tester, const Size(360, 640));
    final results = await _open(tester, 'shape_turn', 2);
    final engine = ShapeTurnEngine.forLevel(2);
    for (var round = 0; round < engine.rounds.length; round++) {
      final answer = engine.rounds[round].answer;
      await tester.tap(find.byKey(ValueKey('shape-option-$round-$answer')));
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(find.byKey(const ValueKey('level-clear')), findsOneWidget);
    expect(results.single.metrics['spatial'], 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shape Turn offers a retry after too many mirrors',
      (tester) async {
    await _view(tester, const Size(390, 844));
    final results = await _open(tester, 'shape_turn', 1);
    final engine = ShapeTurnEngine.forLevel(1);
    for (var round = 0; round < 3; round++) {
      final wrong = (engine.rounds[round].answer + 1) % 4;
      await tester.tap(find.byKey(ValueKey('shape-option-$round-$wrong')));
      await tester.pump(const Duration(milliseconds: 1200));
    }
    expect(find.byKey(const ValueKey('level-retry')), findsOneWidget);
    expect(results, isEmpty);
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('level-retry')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signal Guard is won by tapping only go signals',
      (tester) async {
    await _view(tester, const Size(390, 844));
    final results = await _open(tester, 'signal_guard', 1);
    final engine = SignalGuardEngine.forLevel(1);
    await tester.tap(find.text('START'));
    await tester.pump();
    for (final trial in engine.trials) {
      await tester.pump(Duration(milliseconds: trial.delayMs + 10));
      expect(find.byKey(const ValueKey('signal-glyph')), findsOneWidget);
      if (trial.isGo) {
        await tester.tap(find.byKey(const ValueKey('signal-arena')));
        await tester.pump();
      } else {
        await tester.pump(Duration(milliseconds: engine.windowMs + 10));
      }
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('level-clear')), findsOneWidget);
    expect(results.single.metrics['control'], 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signal Guard leaving the page cancels pending signals',
      (tester) async {
    await _view(tester, const Size(390, 844));
    await _open(tester, 'signal_guard', 1);
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
