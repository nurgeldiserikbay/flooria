import 'dart:math';

enum KnightMove { moved, completed, blocked, ignored }

/// Visit every square once using only chess-knight moves.
class KnightTourEngine {
  KnightTourEngine._(this.level, this.size, List<int> solution)
      : path = [solution.first],
        visited = {solution.first};

  final int level;
  final int size;
  final List<int> path;
  final Set<int> visited;
  bool isCompleted = false;
  int get current => path.last;
  int get goal => size * size;
  int get score => max(100, 1000 - path.length * 4).toInt();
  Set<int> get availableMoves => _legal(current, size).where((cell) =>
      !visited.contains(cell)).toSet();

  factory KnightTourEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final size = safe < 30 ? 5 : 6;
    final random = Random(safe * 9931 + 101);
    List<int>? tour;
    final starts = [for (var cell = 0; cell < size * size; cell++) cell]
      ..shuffle(random);
    for (final start in starts) {
      final visited = List<bool>.filled(size * size, false);
      final path = <int>[];
      var explored = 0;
      bool search(int cell) {
        path.add(cell);
        visited[cell] = true;
        if (path.length == size * size) return true;
        if (++explored > 180000) {
          visited[cell] = false;
          path.removeLast();
          return false;
        }
        final candidates = _legal(cell, size)
          .where((next) => !visited[next]).toList();
        final tieBreak = {for (final next in candidates) next: random.nextDouble()};
        candidates.sort((a, b) {
          final degree = _legal(a, size).where((next) => !visited[next]).length
              .compareTo(_legal(b, size).where((next) => !visited[next]).length);
          return degree != 0 ? degree : tieBreak[a]!.compareTo(tieBreak[b]!);
        });
        for (final next in candidates) {
          if (search(next)) return true;
        }
        visited[cell] = false;
        path.removeLast();
        return false;
      }

      if (search(start)) {
        tour = List<int>.of(path);
        break;
      }
    }
    if (tour == null && size == 6) {
      return KnightTourEngine.forLevel(safe % 29 + 1);
    }
    if (tour == null) throw StateError('Could not generate a knight tour');
    return KnightTourEngine._(safe, size, tour);
  }

  KnightMove move(int cell) {
    if (isCompleted || cell < 0 || cell >= size * size) return KnightMove.ignored;
    if (!availableMoves.contains(cell)) return KnightMove.blocked;
    path.add(cell);
    visited.add(cell);
    if (path.length == goal) {
      isCompleted = true;
      return KnightMove.completed;
    }
    return KnightMove.moved;
  }

  static List<int> _legal(int cell, int size) {
    const deltas = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2),
      (-2, -1), (-2, 1), (-1, 2)];
    final row = cell ~/ size, col = cell % size;
    return [for (final (dr, dc) in deltas)
      if (row + dr >= 0 && row + dr < size && col + dc >= 0 && col + dc < size)
        (row + dr) * size + col + dc];
  }
}
