import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

/// Verify the six visual-only game-feel changes without changing engines.
void main() {
  const gameIds = [
    'snake',
    'brick_break',
    'path_paint',
    'sokoban',
    'merge_tiles',
    'bubble_shooter',
  ];

  for (final gameId in gameIds) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets('$gameId fits ${size.width}x${size.height} and restarts',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final definition = GameRegistry.byId(gameId);
        final results = <GameResult>[];
        await tester.pumpWidget(MaterialApp(
          home: Builder(builder: (context) => definition.buildPage(
            context,
            GameLaunch(
              level: 1,
              mode: GamePlayMode.standalone,
              onComplete: results.add,
            ),
          )),
        ));
        await tester.pump(const Duration(milliseconds: 270));
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL 1'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Restart'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('LEVEL 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(results, isEmpty);
      });
    }
  }
}
