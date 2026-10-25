import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/code_breaker/code_breaker_engine.dart';

void main() {
  test('secrets are deterministic, unique and use symbols 1 through 5', () {
    for (var seed = 0; seed < 200; seed++) {
      final first = CodeBreakerSession(seed: seed);
      final second = CodeBreakerSession(seed: seed);
      expect(first.secret, second.secret);
      expect(first.secret.length, 3);
      expect(first.secret.toSet().length, 3);
      expect(first.secret.every((d) => d >= 1 && d <= 5), isTrue);
    }
  });

  test('feedback distinguishes exact, misplaced and absent symbols', () {
    final game = CodeBreakerSession(seed: 9);
    final code = game.secret;
    final reversed = code.reversed.toList();
    final partial = game.submit(reversed)!;
    expect(partial.exact, 1);
    expect(partial.misplaced, 2);
    expect(game.solved, isFalse);
    final solved = game.submit(code)!;
    expect(solved.exact, 3);
    expect(solved.misplaced, 0);
    expect(game.solved, isTrue);
    expect(game.finished, isTrue);
    expect(game.attempts, 2);
  });

  test('invalid guesses never consume an attempt', () {
    final game = CodeBreakerSession(seed: 4);
    expect(game.submit([1, 1, 2]), isNull);
    expect(game.submit([1, 2]), isNull);
    expect(game.submit([1, 2, 6]), isNull);
    expect(game.submit([]), isNull);
    expect(game.guesses, isEmpty);
  });

  test('last incorrect attempt ends round and prevents additional guesses', () {
    final game = CodeBreakerSession(seed: 5, maxAttempts: 1);
    final wrong = List<int>.generate(3, (i) => game.secret[(i + 1) % 3]);
    expect(game.submit(wrong), isNotNull);
    expect(game.finished, isTrue);
    expect(game.solved, isFalse);
    expect(game.submit(game.secret), isNull);
    expect(game.attempts, 1);
  });
}
