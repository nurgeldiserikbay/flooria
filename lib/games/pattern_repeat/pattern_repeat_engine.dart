import 'dart:math';

enum PatternTapResult { ignored, correct, incorrect, completed }

/// Rules for the single-player sequence memory game.
///
/// A level is a deterministic sequence of cells on a 3x3 board. Wrong taps
/// reset the input position, so the player can try the same pattern again.
class PatternRepeatEngine {
  PatternRepeatEngine._(List<int> sequence)
      : sequence = List<int>.unmodifiable(sequence);

  static const int boardSize = 9;
  static const int maxPatternLength = 24;

  final List<int> sequence;

  int _inputIndex = 0;
  int mistakes = 0;
  bool _completed = false;

  int get inputIndex => _inputIndex;
  bool get isCompleted => _completed;
  int get score => max(0, sequence.length * 100 - mistakes * 15).toInt();

  factory PatternRepeatEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final length = min(3 + safeLevel - 1, maxPatternLength).toInt();
    final random = Random(seed ?? safeLevel * 7919);
    final pattern = <int>[];

    while (pattern.length < length) {
      final next = random.nextInt(boardSize);
      if (pattern.isEmpty || pattern.last != next) pattern.add(next);
    }

    return PatternRepeatEngine._(pattern);
  }

  PatternTapResult tap(int cell) {
    if (_completed || cell < 0 || cell >= boardSize) {
      return PatternTapResult.ignored;
    }

    if (sequence[_inputIndex] != cell) {
      mistakes++;
      _inputIndex = 0;
      return PatternTapResult.incorrect;
    }

    _inputIndex++;
    if (_inputIndex == sequence.length) {
      _completed = true;
      return PatternTapResult.completed;
    }
    return PatternTapResult.correct;
  }
}
