import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/player_stats.dart';

void main() {
  test('Skills are not invented before any game has been completed', () {
    final stats = PlayerGameStats();
    expect(stats.skillRatings.every((s) => s.value == null), isTrue);
    expect(stats.best2048Score, 0);
    expect(stats.sequenceQuestions, 0);
  });

  test('2048 records the best actual tile and score', () {
    final stats = PlayerGameStats();
    stats.record2048(tile: 64, score: 450, moves: 48);
    stats.record2048(tile: 128, score: 1220, moves: 71);
    stats.record2048(tile: 64, score: 900, moves: 42);
    expect(stats.mergeRuns, 3);
    expect(stats.best2048Tile, 128);
    expect(stats.best2048Score, 1220);
    expect(stats.best2048Moves, 71);
    expect(stats.skillRatings[1].value, isNotNull);
    expect(stats.skillRatings[3].value, isNull); // Memory unmeasured.
    expect(stats.skillRatings[4].value, isNull); // Speed unmeasured.
  });

  test('Pattern accuracy uses actual answers and persists in JSON', () {
    final stats = PlayerGameStats();
    stats.recordSequence(correct: 2, questions: 3);
    stats.recordSequence(correct: 3, questions: 3);
    expect(stats.sequenceCorrect, 5);
    expect(stats.sequenceQuestions, 6);
    expect(stats.sequenceBestCorrect, 3);
    final copy = PlayerGameStats.fromJson(stats.toJson());
    expect(copy.sequenceRuns, 2);
    expect(copy.skillRatings[0].value, 100);
    expect(copy.skillRatings[5].value, 83);
    expect(copy.skillRatings[2].value, isNull);
  });

  test('Restoring incomplete legacy stats is safe', () {
    final stats = PlayerGameStats.fromJson({
      'best2048Score': -22, 'sequenceQuestions': 'invalid',
    });
    expect(stats.best2048Score, 0);
    expect(stats.sequenceQuestions, 0);
  });
}
