import 'dart:math';

enum TetrisAction { left, right, down, rotate, hardDrop }
enum TetrisTick { moved, locked, lineClear, completed, failed, ignored }

/// Ten-column falling-block rules with a deterministic randomizer per level.
class TetrisEngine {
  TetrisEngine._({required this.level, required int seed})
      : _random = Random(seed),
        _board = List<int>.filled(width * height, 0) {
    goalLines = min(5 + level ~/ 5, 18).toInt();
    _spawn();
  }

  static const int width = 10;
  static const int height = 20;
  static const List<List<String>> _pieces = [
    ['0000','1111','0000','0000'], // I
    ['0110','0110','0000','0000'], // O
    ['0100','1110','0000','0000'], // T
    ['1000','1110','0000','0000'], // J
    ['0010','1110','0000','0000'], // L
    ['0110','1100','0000','0000'], // S
    ['1100','0110','0000','0000'], // Z
  ];
  final int level;
  final Random _random;
  final List<int> _board;
  late int goalLines;
  int _piece = 0, _rotation = 0, _x = 3, _y = 0;
  int score = 0, clearedLines = 0;
  bool isCompleted = false, isFailed = false;

  List<int> get board => List.unmodifiable(_board);
  int get activeColor => _piece + 1;
  int get gravityMilliseconds => max(130, 900 - (level - 1) * 9).toInt();

  factory TetrisEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    return TetrisEngine._(level: safeLevel,
      seed: seed ?? safeLevel * 7919 + 37);
  }

  List<String> _matrix([int? rotation]) {
    var matrix = List<String>.of(_pieces[_piece]);
    for (var turn = 0; turn < (rotation ?? _rotation); turn++) {
      final next = List.generate(4, (_) => List.filled(4, '0'));
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 4; col++) {
          next[col][3 - row] = matrix[row][col];
        }
      }
      matrix = next.map((row) => row.join()).toList();
    }
    return matrix;
  }

  bool _canPlace(int x, int y, List<String> matrix) {
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        if (matrix[row][col] != '1') continue;
        final boardX = x + col, boardY = y + row;
        if (boardX < 0 || boardX >= width || boardY >= height) return false;
        if (boardY >= 0 && _board[boardY * width + boardX] != 0) return false;
      }
    }
    return true;
  }

  void _spawn() {
    _piece = _random.nextInt(_pieces.length);
    _rotation = 0;
    _x = 3;
    _y = 0;
    if (!_canPlace(_x, _y, _matrix())) isFailed = true;
  }

  TetrisTick tick() {
    if (isCompleted || isFailed) return TetrisTick.ignored;
    if (_canPlace(_x, _y + 1, _matrix())) {
      _y++;
      return TetrisTick.moved;
    }
    return _lock();
  }

  TetrisTick act(TetrisAction action) {
    if (isCompleted || isFailed) return TetrisTick.ignored;
    switch (action) {
      case TetrisAction.left:
        if (_canPlace(_x - 1, _y, _matrix())) _x--;
        return TetrisTick.moved;
      case TetrisAction.right:
        if (_canPlace(_x + 1, _y, _matrix())) _x++;
        return TetrisTick.moved;
      case TetrisAction.down:
        if (_canPlace(_x, _y + 1, _matrix())) {
          _y++;
          score++;
          return TetrisTick.moved;
        }
        return _lock();
      case TetrisAction.rotate:
        final rotated = (_rotation + 1) % 4;
        for (final kick in const [0, -1, 1, -2, 2]) {
          if (_canPlace(_x + kick, _y, _matrix(rotated))) {
            _x += kick;
            _rotation = rotated;
            break;
          }
        }
        return TetrisTick.moved;
      case TetrisAction.hardDrop:
        var distance = 0;
        while (_canPlace(_x, _y + 1, _matrix())) {
          _y++;
          distance++;
        }
        score += distance * 2;
        return _lock();
    }
  }

  TetrisTick _lock() {
    final matrix = _matrix();
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        if (matrix[row][col] != '1') continue;
        final x = _x + col, y = _y + row;
        if (y < 0) {
          isFailed = true;
          return TetrisTick.failed;
        }
        _board[y * width + x] = activeColor;
      }
    }
    final before = clearedLines;
    _clearRows();
    final newLines = clearedLines - before;
    if (newLines > 0) {
      score += [0, 100, 300, 500, 800][min(newLines, 4).toInt()] * level;
    }
    if (clearedLines >= goalLines) {
      isCompleted = true;
      return TetrisTick.completed;
    }
    _spawn();
    if (isFailed) return TetrisTick.failed;
    return newLines > 0 ? TetrisTick.lineClear : TetrisTick.locked;
  }

  void _clearRows() {
    final kept = <List<int>>[];
    for (var row = 0; row < height; row++) {
      final cells = _board.sublist(row * width, (row + 1) * width);
      if (cells.every((cell) => cell != 0)) {
        clearedLines++;
      } else {
        kept.add(cells);
      }
    }
    while (kept.length < height) {
      kept.insert(0, List<int>.filled(width, 0));
    }
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        _board[row * width + col] = kept[row][col];
      }
    }
  }

  List<int> activeCells() {
    final cells = <int>[];
    final matrix = _matrix();
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final y = _y + row, x = _x + col;
        if (matrix[row][col] == '1' && y >= 0 && y < height && x >= 0 && x < width) {
          cells.add(y * width + x);
        }
      }
    }
    return cells;
  }

  /// Cells where the current piece would land if dropped immediately.
  List<int> ghostCells() {
    var landingY = _y;
    while (_canPlace(_x, landingY + 1, _matrix())) {
      landingY++;
    }
    final cells = <int>[];
    final matrix = _matrix();
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final x = _x + col;
        final y = landingY + row;
        if (matrix[row][col] == '1' &&
            y >= 0 && y < height && x >= 0 && x < width) {
          cells.add(y * width + x);
        }
      }
    }
    return cells;
  }
}
