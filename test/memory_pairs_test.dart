import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/memory_pairs.dart';
import 'package:flooria/game/player_stats.dart';
import 'package:flooria/game/floor_engine.dart';
import 'package:flooria/game/game_objective.dart';

void main() {
  test('memory deck contains six exact pairs and seeded order is stable', () {
    final a = MemoryPairs(seed: 17);
    final b = MemoryPairs(seed: 17);
    expect(a.values, b.values);
    expect(a.values.length, 12);
    for (var symbol = 0; symbol < 6; symbol++) {
      expect(a.values.where((value) => value == symbol).length, 2);
    }
  });

  test('memory rejects duplicate taps and hides a mismatch safely', () {
    final game = MemoryPairs(seed: 8);
    expect(game.reveal(0), isTrue);
    expect(game.reveal(0), isFalse);
    final other = game.values.indexWhere((v) => v != game.values[0]);
    expect(game.reveal(other), isTrue);
    expect(game.isResolving, isTrue);
    expect(game.reveal(2), isFalse);
    expect(game.moves, 1);
    game.hideMismatch();
    expect(game.isResolving, isFalse);
    expect(game.isFaceUp(0), isFalse);
  });

  test('memory completes with six pairs and tracks records', () {
    final game = MemoryPairs(seed: 31);
    for (var id = 0; id < 6; id++) {
      final indices = <int>[];
      for (var i = 0; i < game.values.length; i++) {
        if (game.values[i] == id) indices.add(i);
      }
      expect(game.reveal(indices.first), isTrue);
      expect(game.reveal(indices.last), isTrue);
    }
    expect(game.isComplete, isTrue);
    expect(game.pairsFound, 6);
    expect(game.moves, 6);
    final stats = PlayerGameStats();
    stats.recordMemory(pairs: game.pairsFound, moves: game.moves);
    final restored = PlayerGameStats.fromJson(stats.toJson());
    expect(restored.memoryRuns, 1);
    expect(restored.memoryBestPairs, 6);
    expect(restored.memoryBestMoves, 6);
    expect(restored.skillRatings.firstWhere((s) => s.name == 'Memory').value, 100);
  });

  test('memory is available in schedule and objective catalog', () {
    expect(const FloorEngine().challengeFor(3).gameId, 'memory');
    expect(const ObjectiveCatalog().forGame('memory', floor: 3).target, 6);
  });
}
