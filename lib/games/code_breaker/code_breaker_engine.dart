import 'dart:math';

/// Mastermind-style deduction with three distinct symbols from 1..5.
/// A feedback hint is exact-position matches plus wrong-position matches.
class CodeFeedback {
  const CodeFeedback(this.exact, this.misplaced);
  final int exact;
  final int misplaced;
}

class CodeGuess {
  const CodeGuess(this.digits, this.feedback);
  final List<int> digits;
  final CodeFeedback feedback;
}

class CodeBreakerSession {
  CodeBreakerSession({required int seed, this.maxAttempts = 7})
      : assert(maxAttempts > 0),
        secret = _makeSecret(seed);

  final List<int> secret;
  final int maxAttempts;
  final List<CodeGuess> guesses = [];

  bool get solved => guesses.isNotEmpty && guesses.last.feedback.exact == 3;
  bool get finished => solved || guesses.length >= maxAttempts;
  int get attempts => guesses.length;

  static List<int> _makeSecret(int seed) {
    final numbers = [1, 2, 3, 4, 5]..shuffle(Random(seed));
    return List<int>.unmodifiable(numbers.take(3));
  }

  /// Invalid input cannot consume attempts or change session state.
  CodeFeedback? submit(List<int> input) {
    if (finished || input.length != 3 ||
        input.toSet().length != 3 ||
        input.any((number) => number < 1 || number > 5)) {
      return null;
    }
    final exact = List<int>.generate(3, (i) => i)
        .where((i) => secret[i] == input[i]).length;
    final shared = input.where(secret.contains).length;
    final feedback = CodeFeedback(exact, shared - exact);
    guesses.add(CodeGuess(List<int>.unmodifiable(input), feedback));
    return feedback;
  }
}
