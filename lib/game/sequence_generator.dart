import 'dart:math';

/// A deterministic, testable sequence puzzle with four unique answer options.
class SequencePuzzle {
  final List<int> numbers;
  final int answer;
  final List<int> choices;
  final String pattern;
  const SequencePuzzle(this.numbers, this.answer, this.choices, this.pattern);
}

class SequenceGenerator {
  const SequenceGenerator();

  SequencePuzzle generate({required int floor, required int round}) {
    final rng = Random(floor * 7919 + round * 101 + 73);
    final tier = (floor - 1) ~/ 10;
    final kind = tier == 0 ? 0 : (tier == 1 ? round % 2 : round % 3);
    late List<int> values;
    late String pattern;
    if (kind == 0) {
      final start = 2 + rng.nextInt(9 + min<int>(tier * 7, 25));
      final step = 3 + rng.nextInt(5 + min<int>(tier * 3, 14));
      values = List.generate(4, (i) => start + step * i);
      pattern = 'Arithmetic';
    } else if (kind == 1) {
      final start = 1 + rng.nextInt(5);
      final factor = 2 + rng.nextInt(2);
      values = List.generate(4, (i) => start * pow(factor, i).toInt());
      pattern = 'Multiplication';
    } else {
      final start = 1 + rng.nextInt(7);
      final d = 1 + rng.nextInt(3);
      values = List.generate(4, (i) => start + d * i * i);
      pattern = 'Growing differences';
    }
    final answer = values.last;
    final offsets = <int>{
      max<int>(1, answer - 1),
      answer + 1,
      answer + max<int>(2, (answer * .25).round()),
      answer + max<int>(3, (answer * .45).round()),
    }..remove(answer);
    final choices = <int>[answer];
    for (final option in offsets) {
      if (choices.length >= 4) break;
      if (!choices.contains(option)) choices.add(option);
    }
    while (choices.length < 4) {
      choices.add(answer + choices.length * 3 + 2);
    }
    choices.shuffle(rng);
    return SequencePuzzle(values.take(3).toList(), answer, choices, pattern);
  }
}
