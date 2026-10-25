import 'dart:math' as math;

/// Persisted measurements from games, not a medical or cognitive assessment.
/// Future mini-games may contribute additional skill categories.
class PlayerGameStats {
  int best2048Tile;
  int best2048Score;
  int best2048Moves;
  int mergeRuns;
  int sequenceRuns;
  int sequenceCorrect;
  int sequenceQuestions;
  int sequenceBestCorrect;
  int memoryRuns;
  int memoryBestPairs;
  int memoryBestMoves;

  PlayerGameStats({
    this.best2048Tile = 0,
    this.best2048Score = 0,
    this.best2048Moves = 0,
    this.mergeRuns = 0,
    this.sequenceRuns = 0,
    this.sequenceCorrect = 0,
    this.sequenceQuestions = 0,
    this.sequenceBestCorrect = 0,
    this.memoryRuns = 0,
    this.memoryBestPairs = 0,
    this.memoryBestMoves = 0,
  });

  factory PlayerGameStats.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      return value is num ? math.max(0, value.toInt()) : 0;
    }
    return PlayerGameStats(
      best2048Tile: read('best2048Tile'),
      best2048Score: read('best2048Score'),
      best2048Moves: read('best2048Moves'),
      mergeRuns: read('mergeRuns'),
      sequenceRuns: read('sequenceRuns'),
      sequenceCorrect: read('sequenceCorrect'),
      sequenceQuestions: read('sequenceQuestions'),
      sequenceBestCorrect: read('sequenceBestCorrect'),
      memoryRuns: read('memoryRuns'),
      memoryBestPairs: read('memoryBestPairs'),
      memoryBestMoves: read('memoryBestMoves'),
    );
  }

  Map<String, int> toJson() => {
    'best2048Tile': best2048Tile,
    'best2048Score': best2048Score,
    'best2048Moves': best2048Moves,
    'mergeRuns': mergeRuns,
    'sequenceRuns': sequenceRuns,
    'sequenceCorrect': sequenceCorrect,
    'sequenceQuestions': sequenceQuestions,
    'sequenceBestCorrect': sequenceBestCorrect,
    'memoryRuns': memoryRuns,
    'memoryBestPairs': memoryBestPairs,
    'memoryBestMoves': memoryBestMoves,
  };

  void record2048({required int tile, required int score, required int moves}) {
    mergeRuns++;
    if (tile > best2048Tile) {
      best2048Tile = tile;
      best2048Moves = moves;
    } else if (tile == best2048Tile &&
        (best2048Moves == 0 || moves < best2048Moves)) {
      best2048Moves = moves;
    }
    best2048Score = math.max(best2048Score, score);
  }

  void recordSequence({required int correct, required int questions}) {
    if (questions <= 0) return;
    sequenceRuns++;
    sequenceQuestions += questions;
    sequenceCorrect += correct.clamp(0, questions).toInt();
    sequenceBestCorrect = math.max(sequenceBestCorrect, correct);
  }

  void recordMemory({required int pairs, required int moves}) {
    if (moves <= 0) return;
    memoryRuns++;
    if (pairs > memoryBestPairs ||
        (pairs == memoryBestPairs &&
          (memoryBestMoves == 0 || moves < memoryBestMoves))) {
      memoryBestPairs = pairs;
      memoryBestMoves = moves;
    }
  }

  /// A descriptive radar based on player results (0–100 per tracked axis).
  /// A null value means the current games cannot measure this skill yet.
  /// These levels do not measure brain development or intelligence.
  List<GameSkillRating> get skillRatings {
    final has2048 = mergeRuns > 0;
    final hasSequence = sequenceQuestions > 0;
    final accuracy = hasSequence
        ? ((sequenceCorrect / sequenceQuestions) * 100).round() : null;
    int? tilePercent;
    int? scorePercent;
    if (has2048) {
      tilePercent = ((math.log(math.max(2, best2048Tile)) / math.ln2 - 1)
        / 10 * 100).round().clamp(0, 100).toInt();
      scorePercent = ((best2048Score / 2500) * 100)
        .round().clamp(0, 100).toInt();
    }
    return [
      GameSkillRating('Logic', hasSequence
        ? (sequenceBestCorrect / 3 * 100).round().clamp(0, 100).toInt() : null,
        'Number Trail best run'),
      GameSkillRating('Numbers', tilePercent, '2048 best tile'),
      GameSkillRating('Strategy', scorePercent, '2048 best score'),
      GameSkillRating('Memory', memoryRuns > 0
        ? (memoryBestPairs / 6 * 100).round().clamp(0, 100).toInt() : null,
        'Memory Pairs best run'),
      const GameSkillRating('Speed', null, 'Not tracked yet'),
      GameSkillRating('Patterns', accuracy, 'Number Trail accuracy'),
    ];
  }
}

class GameSkillRating {
  const GameSkillRating(this.name, this.value, this.source);
  final String name;
  final int? value;
  final String source;
}
