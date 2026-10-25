import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/shape_shift/shape_shift_engine.dart';

void main() {
  group('ShapeShiftSession', () {
    test('seeded puzzles are deterministic and have one rotational match', () {
      final first = ShapeShiftSession.generatePuzzle(seed: 5150, round: 0);
      final second = ShapeShiftSession.generatePuzzle(seed: 5150, round: 0);
      expect(first.target, second.target);
      expect(first.options, second.options);
      expect(first.answerIndex, second.answerIndex);
      expect(_isRotation(first.target, first.options[first.answerIndex]), isTrue);
      for (var i = 0; i < first.options.length; i++) {
        if (i == first.answerIndex) continue;
        expect(_isRotation(first.target, first.options[i]), isFalse);
      }
    });

    test('rejects invalid or incorrect choices without advancing', () {
      final session = ShapeShiftSession(seed: 981);
      final initial = session.puzzle;
      expect(session.choose(-1), isFalse);
      expect(session.choose(initial.options.length), isFalse);
      final wrong = (initial.answerIndex + 1) % initial.options.length;
      expect(session.choose(wrong), isFalse);
      expect(session.round, 0);
      expect(session.mistakes, 1);
      expect(session.puzzle.target, initial.target);
    });

    test('three correct choices finish exactly once', () {
      final session = ShapeShiftSession(seed: 114);
      for (var round = 0; round < session.roundCount; round++) {
        expect(session.choose(session.puzzle.answerIndex), isTrue);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.choose(session.puzzle.answerIndex), isFalse);
      expect(session.round, 3);
    });

    test('different seeds produce a variety of deterministic puzzles', () {
      final fingerprints = <String>{};
      for (var seed = 0; seed < 40; seed++) {
        final puzzle = ShapeShiftSession.generatePuzzle(seed: seed, round: 0);
        fingerprints.add('${puzzle.target}:${puzzle.options}');
      }
      expect(fingerprints.length, greaterThan(10));
    });
  });
}

bool _isRotation(List<ShapeCell> shape, List<ShapeCell> candidate) {
  var rotated = shape;
  for (var turn = 0; turn < 4; turn++) {
    if (_sameShape(rotated, candidate)) return true;
    rotated = _normalize(rotated.map((cell) => (cell.$2, -cell.$1)).toList());
  }
  return false;
}

bool _sameShape(List<ShapeCell> a, List<ShapeCell> b) {
  if (a.length != b.length) return false;
  final left = _normalize(a);
  final right = _normalize(b);
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

List<ShapeCell> _normalize(List<ShapeCell> shape) {
  final minRow = shape.map((cell) => cell.$1).reduce((a, b) => a < b ? a : b);
  final minColumn = shape.map((cell) => cell.$2).reduce((a, b) => a < b ? a : b);
  final result = shape.map((cell) => (cell.$1 - minRow, cell.$2 - minColumn)).toList()
    ..sort((a, b) => a.$1 != b.$1
        ? a.$1.compareTo(b.$1)
        : a.$2.compareTo(b.$2));
  return result;
}
