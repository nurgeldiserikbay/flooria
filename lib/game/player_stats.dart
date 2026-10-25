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
  int colorRuns;
  int colorCorrect;
  int colorQuestions;
  int colorBestCorrect;
  int speedRuns;
  int speedBestMillis;
  int speedBestMistakes;

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
    this.colorRuns = 0,
    this.colorCorrect = 0,
    this.colorQuestions = 0,
    this.colorBestCorrect = 0,
    this.speedRuns = 0,
    this.speedBestMillis = 0,
    this.speedBestMistakes = 0,
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
      colorRuns: read('colorRuns'),
      colorCorrect: read('colorCorrect'),
      colorQuestions: read('colorQuestions'),
      colorBestCorrect: read('colorBestCorrect'),
      speedRuns: read('speedRuns'),
      speedBestMillis: read('speedBestMillis'),
      speedBestMistakes: read('speedBestMistakes'),
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
    'colorRuns': colorRuns,
    'colorCorrect': colorCorrect,
    'colorQuestions': colorQuestions,
    'colorBestCorrect': colorBestCorrect,
    'speedRuns': speedRuns,
    'speedBestMillis': speedBestMillis,
    'speedBestMistakes': speedBestMistakes,
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

  void recordColorSpot({required int correct, required int total}) {
    if (total <= 0) return;
    colorRuns++;
    colorQuestions += total;
    colorCorrect += correct.clamp(0, total).toInt();
    colorBestCorrect = math.max(colorBestCorrect, correct.clamp(0, total).toInt());
  }

  void recordSpeed({required int elapsedMillis, required int mistakes}) {
    if (elapsedMillis <= 0) return;
    speedRuns++;
    if (speedBestMillis == 0 || elapsedMillis < speedBestMillis) {
      speedBestMillis = elapsedMillis;
      speedBestMistakes = math.max(0, mistakes);
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
      GameSkillRating('Speed', speedBestMillis > 0
        ? ((60000 - speedBestMillis) / 60000 * 100)
          .round().clamp(0, 100).toInt() : null,
        'Tap Sprint best finish time'),
      GameSkillRating('Patterns', accuracy, 'Number Trail accuracy'),
      GameSkillRating('Perception', colorQuestions > 0
        ? (colorCorrect / colorQuestions * 100).round().clamp(0, 100).toInt()
        : null, 'Color Spot accuracy'),
    ];
  }
}

class GameSkillRating {
  const GameSkillRating(this.name, this.value, this.source);
  final String name;
  final int? value;
  final String source;
}
