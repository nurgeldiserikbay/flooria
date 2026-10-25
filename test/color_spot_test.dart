import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/color_spot.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';

void main() {
  test('each round has a single identifiable different shade', () {
    final session = ColorSpotSession(seed: 77);
    for (var round = 0; round < 5; round++) {
      final puzzle = session.current;
      expect(puzzle.colors.length, 9);
      final odd = puzzle.colors[puzzle.oddIndex];
      expect(puzzle.colors.where((v) => v == odd).length, 1);
      expect(puzzle.colors.toSet().length, 2);
      expect(session.answer(puzzle.oddIndex), isTrue);
    }
    expect(session.finished, isTrue);
    expect(session.correct, 5);
  });

  test('wrong choices are counted but not rewarded', () {
    final session = ColorSpotSession(seed: 4);
    final wrong = (session.current.oddIndex + 1) % 9;
    expect(session.answer(wrong), isFalse);
    expect(session.round, 1);
    expect(session.correct, 0);
  });

  test('rounds repeat deterministically for matching seeds', () {
    final a = ColorSpotSession(seed: 101);
    final b = ColorSpotSession(seed: 101);
    expect(a.current.colors, b.current.colors);
    expect(a.current.oddIndex, b.current.oddIndex);
  });

  test('color performance persists and is not misreported as memory', () {
    final stats = PlayerGameStats();
    stats.recordColorSpot(correct: 4, total: 5);
    final restored = PlayerGameStats.fromJson(stats.toJson());
    expect(restored.colorRuns, 1);
    expect(restored.colorBestCorrect, 4);
    expect(restored.skillRatings.last.value, 80);
    expect(restored.skillRatings.firstWhere((r) => r.name == 'Memory').value,
      isNull);
  });

  test('color spot is fourth game in route with a real goal', () {
    expect(const FloorEngine().challengeFor(4).gameId, 'colorMatch');
    expect(const ObjectiveCatalog().forGame('colorMatch', floor: 4).target, 4);
  });
}
