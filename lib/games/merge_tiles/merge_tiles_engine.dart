import 'dart:math';

enum MergeDirection { up, right, down, left }
enum MergeResult { moved, ignored, completed, failed }

/// 4x4 merge puzzle. A valid swipe compresses and merges each tile at most once.
class MergeTilesEngine {
  MergeTilesEngine._({required this.level, required this.target, required int seed})
      : _random = Random(seed),
        _board = List<int>.filled(16, 0) {
    _spawn();
    _spawn();
  }

  static const int side = 4;
  final int level;
  final int target;
  final Random _random;
  final List<int> _board;
  List<int> get board => List.unmodifiable(_board);
  int score = 0;
  int moves = 0;
  bool isCompleted = false;
  bool isFailed = false;

  factory MergeTilesEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final exponent = (5 + (safeLevel - 1) ~/ 8).clamp(5, 13).toInt();
    return MergeTilesEngine._(
      level: safeLevel,
      target: 1 << exponent,
      seed: seed ?? safeLevel * 65537 + 11,
    );
  }

  void _spawn() {
    final empty = [for (var i = 0; i < _board.length; i++) if (_board[i] == 0) i];
    if (empty.isEmpty) return;
    final index = empty[_random.nextInt(empty.length)];
    _board[index] = _random.nextInt(10) == 0 ? 4 : 2;
  }

  static (List<int>, int) _merge(List<int> line) {
    final packed = line.where((value) => value != 0).toList();
    final result = <int>[];
    var mergeScore = 0;
    for (var i = 0; i < packed.length; i++) {
      if (i + 1 < packed.length && packed[i] == packed[i + 1]) {
        final merged = packed[i] * 2;
        result.add(merged);
        mergeScore += merged;
        i++;
      } else {
        result.add(packed[i]);
      }
    }
    return ([...result, ...List<int>.filled(side - result.length, 0)], mergeScore);
  }

  List<int> _lineIndices(int line, MergeDirection direction) => switch (direction) {
    MergeDirection.left => [for (var c = 0; c < side; c++) line * side + c],
    MergeDirection.right => [for (var c = side - 1; c >= 0; c--) line * side + c],
    MergeDirection.up => [for (var r = 0; r < side; r++) r * side + line],
    MergeDirection.down => [for (var r = side - 1; r >= 0; r--) r * side + line],
  };

  MergeResult move(MergeDirection direction) {
    if (isCompleted || isFailed) return MergeResult.ignored;
    final before = List<int>.of(_board);
    for (var line = 0; line < side; line++) {
      final indices = _lineIndices(line, direction);
      final (merged, lineScore) = _merge(indices.map((index) => _board[index]).toList());
      score += lineScore;
      for (var i = 0; i < side; i++) {
        _board[indices[i]] = merged[i];
      }
    }
    if (_sameBoard(before, _board)) return MergeResult.ignored;
    moves++;
    if (_board.any((value) => value >= target)) {
      isCompleted = true;
      return MergeResult.completed;
    }
    _spawn();
    if (!_hasMove()) {
      isFailed = true;
      return MergeResult.failed;
    }
    return MergeResult.moved;
  }

  bool _sameBoard(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _hasMove() {
    if (_board.contains(0)) return true;
    for (var row = 0; row < side; row++) {
      for (var col = 0; col < side; col++) {
        final value = _board[row * side + col];
        if (col + 1 < side && value == _board[row * side + col + 1]) return true;
        if (row + 1 < side && value == _board[(row + 1) * side + col]) return true;
      }
    }
    return false;
  }
}
