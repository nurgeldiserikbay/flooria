import 'dart:math';

enum MatchstickPickResult { invalid, incorrect, correct, complete }

class MatchstickMove {
  const MatchstickMove({
    required this.fromGlyph,
    required this.fromSegment,
    required this.toGlyph,
    required this.toSegment,
  });

  final int fromGlyph;
  final int fromSegment;
  final int toGlyph;
  final int toSegment;

  @override
  bool operator ==(Object other) =>
      other is MatchstickMove &&
      fromGlyph == other.fromGlyph &&
      fromSegment == other.fromSegment &&
      toGlyph == other.toGlyph &&
      toSegment == other.toSegment;

  @override
  int get hashCode =>
      Object.hash(fromGlyph, fromSegment, toGlyph, toSegment);
}

abstract final class MatchstickGlyph {
  static const Map<String, List<int>> _segments = {
    '0': [0, 1, 2, 3, 4, 5],
    '1': [1, 2],
    '2': [0, 1, 6, 4, 3],
    '3': [0, 1, 2, 3, 6],
    '4': [5, 6, 1, 2],
    '5': [0, 5, 6, 2, 3],
    '6': [0, 5, 6, 4, 3, 2],
    '7': [0, 1, 2],
    '8': [0, 1, 2, 3, 4, 5, 6],
    '9': [0, 1, 2, 3, 5, 6],
    '+': [6, 7, 8],
    '-': [6],
    '=': [0, 3],
  };

  static const List<int> segmentIds = [0, 1, 2, 3, 4, 5, 6, 7, 8];

  static Set<int> segmentsFor(String glyph) {
    final segments = _segments[glyph];
    if (segments == null) throw ArgumentError.value(glyph, 'glyph');
    return Set<int>.unmodifiable(segments);
  }

  static String? fromSegments(Set<int> segments) {
    for (final entry in _segments.entries) {
      if (_sameSet(segments, entry.value.toSet())) return entry.key;
    }
    return null;
  }

  static String segmentName(int segment) => switch (segment) {
        0 => 'top',
        1 => 'upper-right',
        2 => 'lower-right',
        3 => 'bottom',
        4 => 'lower-left',
        5 => 'upper-left',
        6 => 'middle',
        7 => 'upper vertical',
        _ => 'lower vertical',
      };

  static bool _sameSet(Set<int> first, Set<int> second) =>
      first.length == second.length && first.containsAll(second);
}

class MatchstickEquation {
  MatchstickEquation(Iterable<String> glyphs)
      : glyphs = List<String>.unmodifiable(glyphs) {
    if (this.glyphs.length != 5 ||
        this.glyphs[1] != '+' && this.glyphs[1] != '-' ||
        this.glyphs[3] != '=' ||
        this.glyphs.any((glyph) => MatchstickGlyph._segments[glyph] == null)) {
      throw ArgumentError('Equation must have the form A + B = C.');
    }
  }

  final List<String> glyphs;

  String get label => glyphs.join(' ');
  bool get isTrue {
    final first = int.tryParse(glyphs[0]);
    final second = int.tryParse(glyphs[2]);
    final result = int.tryParse(glyphs[4]);
    if (first == null || second == null || result == null) return false;
    return glyphs[1] == '+' ? first + second == result : first - second == result;
  }

  MatchstickEquation? apply(MatchstickMove move) {
    const editableGlyphs = [0, 1, 2, 4];
    if (!editableGlyphs.contains(move.fromGlyph) ||
        !editableGlyphs.contains(move.toGlyph) ||
        move.fromGlyph == move.toGlyph ||
        !MatchstickGlyph.segmentIds.contains(move.fromSegment) ||
        !MatchstickGlyph.segmentIds.contains(move.toSegment)) {
      return null;
    }

    final source = Set<int>.of(
      MatchstickGlyph.segmentsFor(glyphs[move.fromGlyph]),
    );
    final destination = Set<int>.of(
      MatchstickGlyph.segmentsFor(glyphs[move.toGlyph]),
    );
    if (!source.contains(move.fromSegment) ||
        destination.contains(move.toSegment)) {
      return null;
    }
    source.remove(move.fromSegment);
    destination.add(move.toSegment);
    final newSource = MatchstickGlyph.fromSegments(source);
    final newDestination = MatchstickGlyph.fromSegments(destination);
    if (newSource == null || newDestination == null) return null;

    final changed = List<String>.of(glyphs);
    changed[move.fromGlyph] = newSource;
    changed[move.toGlyph] = newDestination;
    return MatchstickEquation(changed);
  }

  List<MatchstickMove> get possibleMoves {
    const editableGlyphs = [0, 1, 2, 4];
    final moves = <MatchstickMove>[];
    for (final fromGlyph in editableGlyphs) {
      final source = MatchstickGlyph.segmentsFor(glyphs[fromGlyph]);
      for (final fromSegment in source) {
        for (final toGlyph in editableGlyphs) {
          if (toGlyph == fromGlyph) continue;
          final destination = MatchstickGlyph.segmentsFor(glyphs[toGlyph]);
          for (final toSegment in MatchstickGlyph.segmentIds) {
            if (destination.contains(toSegment)) continue;
            final move = MatchstickMove(
              fromGlyph: fromGlyph,
              fromSegment: fromSegment,
              toGlyph: toGlyph,
              toSegment: toSegment,
            );
            if (apply(move) != null) moves.add(move);
          }
        }
      }
    }
    return List<MatchstickMove>.unmodifiable(moves);
  }
}

class MatchstickPuzzle {
  MatchstickPuzzle({
    required this.equation,
    required this.answer,
    required Iterable<MatchstickMove> choices,
  }) : choices = List<MatchstickMove>.unmodifiable(choices);

  final MatchstickEquation equation;
  final MatchstickMove answer;
  final List<MatchstickMove> choices;
}

class MatchstickMathSession {
  MatchstickMathSession({required this.seed}) {
    final random = Random(seed);
    final pool = List<MatchstickEquation>.of(_puzzlePool)..shuffle(random);
    puzzles = List<MatchstickPuzzle>.unmodifiable([
      for (final equation in pool.take(roundCount))
        _makePuzzle(equation, random),
    ]);
  }

  static const int roundCount = 5;
  final int seed;
  late final List<MatchstickPuzzle> puzzles;
  int roundIndex = 0;
  int correctAnswers = 0;
  int mistakes = 0;

  bool get finished => roundIndex >= roundCount;
  double get progress => roundIndex / roundCount;
  MatchstickPuzzle get current =>
      puzzles[roundIndex.clamp(0, roundCount - 1).toInt()];

  MatchstickPickResult choose(int choiceIndex) {
    if (finished || choiceIndex < 0 || choiceIndex >= current.choices.length) {
      return MatchstickPickResult.invalid;
    }
    if (current.choices[choiceIndex] != current.answer) {
      mistakes++;
      return MatchstickPickResult.incorrect;
    }
    correctAnswers++;
    roundIndex++;
    return finished
        ? MatchstickPickResult.complete
        : MatchstickPickResult.correct;
  }

  MatchstickPuzzle _makePuzzle(
    MatchstickEquation equation,
    Random random,
  ) {
    final solutions = equation.possibleMoves
        .where((move) => equation.apply(move)?.isTrue ?? false)
        .toList();
    if (solutions.length != 1) {
      throw StateError('Puzzle pool must contain a unique one-match solution.');
    }
    final answer = solutions.single;
    final alternatives = equation.possibleMoves
        .where((move) => move != answer)
        .toList()
      ..shuffle(random);
    final choices = <MatchstickMove>[
      answer,
      ...alternatives.take(2),
    ]..shuffle(random);
    return MatchstickPuzzle(
      equation: equation,
      answer: answer,
      choices: choices,
    );
  }

  static final List<MatchstickEquation> _puzzlePool = _buildPuzzlePool();

  static List<MatchstickEquation> _buildPuzzlePool() {
    final unique = <String, MatchstickEquation>{};
    for (var first = 0; first <= 9; first++) {
      for (var second = 0; second <= 9; second++) {
        for (final operation in ['+', '-']) {
          final result = operation == '+' ? first + second : first - second;
          if (result < 0 || result > 9) continue;
          final solved = MatchstickEquation([
            '$first',
            operation,
            '$second',
            '=',
            '$result',
          ]);

          for (final move in solved.possibleMoves) {
            final puzzle = solved.apply(move);
            if (puzzle == null || puzzle.isTrue) continue;
            final solutions = puzzle.possibleMoves
                .where((candidate) => puzzle.apply(candidate)?.isTrue ?? false)
                .toList();
            if (solutions.length != 1) continue;
            unique.putIfAbsent(puzzle.glyphs.join(), () => puzzle);
          }
        }
      }
    }
    final puzzles = List<MatchstickEquation>.unmodifiable(unique.values);
    if (puzzles.length < roundCount) {
      throw StateError('Could not generate enough unique matchstick puzzles.');
    }
    return puzzles;
  }
}
