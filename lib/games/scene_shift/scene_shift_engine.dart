import 'dart:math';

enum SceneShape { circle, square, triangle, diamond, star }

enum SceneColor { coral, blue, yellow, mint, purple }

enum SceneShiftResult { invalid, incorrect, correct, complete }

/// One preview scene and the next scene, with exactly one changed tile.
class SceneShiftRound {
  SceneShiftRound({
    required this.columns,
    required this.changedIndex,
    required Iterable<SceneToken> before,
    required Iterable<SceneToken> after,
  })  : before = List<SceneToken>.unmodifiable(before),
        after = List<SceneToken>.unmodifiable(after) {
    if (columns < 1 ||
        this.before.isEmpty ||
        this.before.length != this.after.length ||
        changedIndex < 0 ||
        changedIndex >= this.before.length ||
        this.before[changedIndex] == this.after[changedIndex]) {
      throw ArgumentError('A scene shift must change one valid tile.');
    }
    final changes = [
      for (var index = 0; index < this.before.length; index++)
        if (this.before[index] != this.after[index]) index,
    ];
    if (changes.length != 1 || changes.single != changedIndex) {
      throw ArgumentError('A scene shift must have exactly one change.');
    }
  }

  final int columns;
  final int changedIndex;
  final List<SceneToken> before;
  final List<SceneToken> after;

  int get rows => (before.length / columns).ceil();
}

class SceneToken {
  const SceneToken({required this.shape, required this.color});

  final SceneShape shape;
  final SceneColor color;

  @override
  bool operator ==(Object other) =>
      other is SceneToken && shape == other.shape && color == other.color;

  @override
  int get hashCode => Object.hash(shape, color);
}

class SceneShiftSession {
  SceneShiftSession({required this.seed, int level = 1}) {
    final random = Random(seed);
    final extraCells = ((level - 1) ~/ 3).clamp(0, 4).toInt();
    rounds = List<SceneShiftRound>.unmodifiable([
      for (var index = 0; index < roundCount; index++)
        _makeRound(
          random,
          (_baseCellCounts[index] + extraCells).clamp(9, 20).toInt(),
        ),
    ]);
  }

  static const int roundCount = 5;
  static const int passScore = 4;
  static const List<int> _baseCellCounts = [9, 12, 16, 16, 20];

  final int seed;
  late final List<SceneShiftRound> rounds;
  int roundIndex = 0;
  int correctFinds = 0;
  int mistakes = 0;
  bool _awaitingAnswer = false;

  bool get finished => roundIndex >= roundCount;
  bool get passed => finished && correctFinds >= passScore;
  bool get showingPreview => !finished && !_awaitingAnswer;
  bool get awaitingAnswer => !finished && _awaitingAnswer;
  double get progress => roundIndex / roundCount;
  SceneShiftRound get current =>
      rounds[roundIndex.clamp(0, roundCount - 1).toInt()];
  List<SceneToken> get visibleScene =>
      showingPreview ? current.before : current.after;

  /// Hides the preview and reveals the changed scene.
  bool reveal() {
    if (finished || _awaitingAnswer) return false;
    _awaitingAnswer = true;
    return true;
  }

  SceneShiftResult choose(int tileIndex) {
    if (!awaitingAnswer || tileIndex < 0 || tileIndex >= current.after.length) {
      return SceneShiftResult.invalid;
    }
    if (tileIndex != current.changedIndex) {
      mistakes++;
      return SceneShiftResult.incorrect;
    }

    correctFinds++;
    roundIndex++;
    _awaitingAnswer = false;
    return finished ? SceneShiftResult.complete : SceneShiftResult.correct;
  }

  SceneShiftRound _makeRound(Random random, int cellCount) {
    final before = List<SceneToken>.generate(
      cellCount,
      (_) => SceneToken(
        shape: SceneShape.values[random.nextInt(SceneShape.values.length)],
        color: SceneColor.values[random.nextInt(SceneColor.values.length)],
      ),
    );
    final changedIndex = random.nextInt(cellCount);
    final after = List<SceneToken>.of(before);
    final token = before[changedIndex];

    if (random.nextBool()) {
      var shape = SceneShape.values[random.nextInt(SceneShape.values.length)];
      while (shape == token.shape) {
        shape = SceneShape.values[random.nextInt(SceneShape.values.length)];
      }
      after[changedIndex] = SceneToken(shape: shape, color: token.color);
    } else {
      var color = SceneColor.values[random.nextInt(SceneColor.values.length)];
      while (color == token.color) {
        color = SceneColor.values[random.nextInt(SceneColor.values.length)];
      }
      after[changedIndex] = SceneToken(shape: token.shape, color: color);
    }

    return SceneShiftRound(
      columns: cellCount <= 9 ? 3 : 4,
      changedIndex: changedIndex,
      before: before,
      after: after,
    );
  }
}
