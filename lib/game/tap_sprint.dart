import 'dart:math';

/// Tap numbers in ascending order on a shuffled 3x3 board.
/// Game rules are pure Dart; the UI supplies elapsed milliseconds.
class TapSprintSession {
  TapSprintSession({required int seed}) {
    values = List<int>.generate(9, (i) => i + 1)
      ..shuffle(Random(seed));
  }

  late final List<int> values;
  int expected = 1;
  int mistakes = 0;
  int get completed => expected - 1;
  bool get finished => expected > 9;

  bool tap(int index) {
    if (finished || index < 0 || index >= values.length) return false;
    if (values[index] == expected) {
      expected++;
      return true;
    }
    // A completed cell is inert, not a mistaken input.
    if (values[index] > expected) mistakes++;
    return false;
  }
}
