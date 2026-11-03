import 'dart:math';

enum TangramMove { selected, rotated, placed, completed, blocked, ignored }

class _PiecePlacement {
  const _PiecePlacement(this.anchor, this.rotation, this.cells);
  final Point<int> anchor;
  final int rotation;
  final List<Point<int>> cells;
}

/// Place and rotate four polyomino pieces to fill a hidden silhouette.
class TangramFitEngine {
  TangramFitEngine._(this.level, this._shapes, this.targetCells)
      : rotations = [for (var i = 0; i < _shapes.length; i++) (level + i) % 4],
        anchors = List<Point<int>?>.filled(_shapes.length, null);

  static const int side = 5;
  static const List<List<Point<int>>> _baseShapes = [
    [Point(0, 0), Point(1, 0), Point(1, 1)],
    [Point(0, 0), Point(1, 0), Point(2, 0)],
    [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)],
    [Point(0, 0), Point(1, 0), Point(2, 0), Point(1, 1)],
  ];

  final int level;
  final List<List<Point<int>>> _shapes;
  final Set<int> targetCells;
  final List<int> rotations;
  final List<Point<int>?> anchors;
  int? selectedPiece;
  int moves = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 - moves * 10).toInt();
  int get placedCount => anchors.where((anchor) => anchor != null).length;

  factory TangramFitEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 13709 + 109);
    final solutions = List<_PiecePlacement?>.filled(_baseShapes.length, null);
    final occupied = <int>{};
    bool pack(int piece) {
      if (piece >= _baseShapes.length) return true;
      final candidates = <_PiecePlacement>[];
      for (var rotation = 0; rotation < 4; rotation++) {
        final cells = _rotate(_baseShapes[piece], rotation);
        final maxX = cells.map((point) => point.x).reduce(max);
        final maxY = cells.map((point) => point.y).reduce(max);
        for (var row = 0; row <= side - maxY - 1; row++) {
          for (var col = 0; col <= side - maxX - 1; col++) {
            final boardCells = [for (final point in cells)
              (row + point.y) * side + col + point.x];
            if (boardCells.every((cell) => !occupied.contains(cell))) {
              candidates.add(_PiecePlacement(Point<int>(col, row), rotation, cells));
            }
          }
        }
      }
      candidates.shuffle(random);
      for (final candidate in candidates) {
        final boardCells = [for (final point in candidate.cells)
          (candidate.anchor.y + point.y) * side + candidate.anchor.x + point.x];
        occupied.addAll(boardCells);
        solutions[piece] = candidate;
        if (pack(piece + 1)) return true;
        occupied.removeAll(boardCells);
        solutions[piece] = null;
      }
      return false;
    }

    if (!pack(0)) throw StateError('Could not generate a tangram silhouette');
    return TangramFitEngine._(safe, _baseShapes,
      {for (final cell in occupied) cell});
  }

  void selectPiece(int piece) {
    if (piece < 0 || piece >= _shapes.length || isCompleted) return;
    if (anchors[piece] != null) anchors[piece] = null;
    selectedPiece = piece;
    moves++;
  }

  TangramMove rotateSelected() {
    final selected = selectedPiece;
    if (selected == null || isCompleted) return TangramMove.ignored;
    rotations[selected] = (rotations[selected] + 1) % 4;
    moves++;
    return TangramMove.rotated;
  }

  TangramMove placeSelected(int boardCell) {
    final selected = selectedPiece;
    if (selected == null || isCompleted || boardCell < 0 ||
        boardCell >= side * side) return TangramMove.ignored;
    final anchor = Point<int>(boardCell % side, boardCell ~/ side);
    final cells = _boardCells(selected, anchor);
    if (cells.any((cell) => !targetCells.contains(cell)) ||
        cells.toSet().length != cells.length || _overlapsOther(selected, cells)) {
      return TangramMove.blocked;
    }
    anchors[selected] = anchor;
    selectedPiece = null;
    moves++;
    isCompleted = placedCount == _shapes.length && _occupiedCount() == targetCells.length;
    return isCompleted ? TangramMove.completed : TangramMove.placed;
  }

  List<Point<int>> shapeCells(int piece) => _rotate(_shapes[piece], rotations[piece]);
  Point<int>? anchorOf(int piece) => anchors[piece];

  List<int> cellsOf(int piece) {
    final anchor = anchors[piece];
    return anchor == null ? const [] : _boardCells(piece, anchor);
  }

  bool _overlapsOther(int piece, List<int> cells) {
    final occupied = <int>{};
    for (var other = 0; other < anchors.length; other++) {
      if (other == piece || anchors[other] == null) continue;
      occupied.addAll(_boardCells(other, anchors[other]!));
    }
    return cells.any(occupied.contains);
  }

  List<int> _boardCells(int piece, Point<int> anchor) => [
    for (final point in shapeCells(piece))
      if (anchor.x + point.x < side && anchor.y + point.y < side)
        (anchor.y + point.y) * side + anchor.x + point.x
      else
        -1,
  ];

  int _occupiedCount() => {
    for (var piece = 0; piece < anchors.length; piece++)
      if (anchors[piece] != null) ..._boardCells(piece, anchors[piece]!),
  }.length;

  static List<Point<int>> _rotate(List<Point<int>> shape, int turns) {
    var result = List<Point<int>>.of(shape);
    for (var turn = 0; turn < turns; turn++) {
      final maxY = result.map((point) => point.y).reduce(max);
      result = [for (final point in result) Point<int>(maxY - point.y, point.x)];
    }
    final minX = result.map((point) => point.x).reduce(min);
    final minY = result.map((point) => point.y).reduce(min);
    return [for (final point in result)
      Point<int>(point.x - minX, point.y - minY)];
  }
}
