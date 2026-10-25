import 'dart:math';

/// Reproduce the flashed pad sequence, in order. Framework-free rules.
class PatternEchoSession {
  PatternEchoSession({required this.seed});

  final int seed;
  static const int stages = 3;
  int stage = 0;
  int cursor = 0;
  int mistakes = 0;

  bool get complete => stage >= stages;
  int get stageLength => 2 + stage;

  List<int> get pattern {
    if (complete) return const [];
    final random = Random((seed * 7919 + stage * 104729) & 0x7fffffff);
    return List<int>.generate(stageLength, (_) => random.nextInt(4));
  }

  /// -1 = incorrect; 0 = valid partial input; 1 = stage completed;
  /// 2 = all stages finished.
  int input(int pad) {
    if (complete || pad < 0 || pad > 3) return -1;
    if (pattern[cursor] != pad) {
      mistakes++;
      cursor = 0;
      return -1;
    }
    cursor++;
    if (cursor < stageLength) return 0;
    stage++;
    cursor = 0;
    return complete ? 2 : 1;
  }
}
