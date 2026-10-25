import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/fifteen.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/ui/fifteen_page.dart';

void main() {
  test('seeded layouts are reproducible, not solved and always permuted', () {
    for (var seed = 0; seed < 70; seed++) {
      final game = FifteenSession(seed: seed);
      expect(game.isSolved, isFalse);
      expect(game.tiles.toSet(), Set<int>.from(List<int>.generate(16, (i) => i)));
      expect(FifteenSession(seed: seed).tiles, game.tiles);
      expect(game.moves, 0);
    }
  });

  test('rejects nonadjacent taps, and every legal move can be undone', () {
    final game = FifteenSession(seed: 43);
    final before = List<int>.from(game.tiles);
    final blank = game.blankIndex;
    final playable = game.movableIndices.first;
    expect(game.move(blank), isFalse);
    expect(game.move(playable), isTrue);
    expect(game.moves, 1);
    expect(game.move(blank), isTrue);
    expect(game.tiles, before);
    expect(game.moves, 2);
  });

  test('campaign includes fifteenth puzzle with appropriate objective', () {
    expect(const FloorEngine().challengeFor(8).gameId, 'fifteen');
    expect(const ObjectiveCatalog().forGame('fifteen').target, 15);
  });

  test('best-move record persists and legacy stats remain safe', () {
    final stats = PlayerGameStats.fromJson({'mergeRuns': 4});
    stats.recordFifteen(moves: 33);
    stats.recordFifteen(moves: 25);
    final copy = PlayerGameStats.fromJson(stats.toJson());
    expect(copy.fifteenRuns, 2);
    expect(copy.fifteenBestMoves, 25);
    expect(copy.mergeRuns, 4);
  });

  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Fifteen board fits without page scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: FifteenPage(
        onComplete: () {},
        onSessionEnd: (_) {},
      )));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
