import 'dart:math';

enum SequenceAnswer { correct, wrong, completed, ignored }

/// Find the next value in a short number pattern. Each level has five rounds.
class NumberSequenceEngine {
  NumberSequenceEngine._(this.level);

  final int level;
  int round = 0;
  late List<int> terms;
  late List<int> choices;
  late int answer;
  int correct = 0;
  int mistakes = 0;
  bool _complete = false;

  bool get isCompleted => _complete;
  int get score => max(100, correct * 200 - mistakes * 35).toInt();

  factory NumberSequenceEngine.forLevel(int level) {
    final engine = NumberSequenceEngine._(max(1, level).toInt());
    engine._loadRound();
    return engine;
  }

  void _loadRound() {
    final random = Random(level * 32771 + round * 97);
    final kind = level < 4 ? 0 : level < 8 ? 1 : 2;
    late final List<int> values;
    if (kind == 0) {
      final step = 2 + random.nextInt(7 + level);
      final start = 1 + random.nextInt(18);
      values = [for (var i = 0; i < 5; i++) start + i * step];
    } else if (kind == 1) {
      final factor = 2 + random.nextInt(2);
      final start = 1 + random.nextInt(4);
      values = [for (var i = 0; i < 5; i++) start * pow(factor, i).toInt()];
    } else {
      final step = 2 + random.nextInt(5);
      final start = random.nextInt(8);
      values = [for (var i = 0; i < 5; i++) start + step * i * i];
    }
    answer = values.last;
    terms = List<int>.unmodifiable(values.take(4));
    final candidates = <int>{answer};
    while (candidates.length < 4) {
      final offset = 1 + random.nextInt(max(3, answer ~/ 2 + 2).toInt());
      candidates.add(random.nextBool() ? answer + offset
        : max(0, answer - offset).toInt());
    }
    choices = candidates.toList()..shuffle(random);
  }

  SequenceAnswer choose(int value) {
    if (_complete || !choices.contains(value)) return SequenceAnswer.ignored;
    if (value != answer) {
      mistakes++;
      return SequenceAnswer.wrong;
    }
    correct++;
    if (correct >= 5) {
      _complete = true;
      return SequenceAnswer.completed;
    }
    round++;
    _loadRound();
    return SequenceAnswer.correct;
  }
}
