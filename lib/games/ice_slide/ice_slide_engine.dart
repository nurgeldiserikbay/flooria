import 'dart:collection';
import 'dart:math';

enum SlideDirection { up, right, down, left }

enum SlideResult { ignored, moved, completed }

/// The puck slides until a block or the board edge stops it. The goal is a
/// stop reachable from the start; [par] is its breadth-first shortest route.
class IceSlideEngine {
  IceSlideEngine._({
    required this.level,
    required this.size,
    required Set<int> blocks,
    required this.start,
    required this.goal,
    required this.par,
  })  : blocks = Set<int>.unmodifiable(blocks),
        _position = start;

  final int level;
  final int size;
  final Set<int> blocks;
  final int start;
  final int goal;
  final int par;

  int _position;
  final List<int> _history = [];
  int moves = 0;
  bool _completed = false;

  int get position => _position;
  bool get isCompleted => _completed;
  bool get canUndo => _history.isNotEmpty && !_completed;
  List<int> get trail => List<int>.unmodifiable([..._history, _position]);

  int get stars => moves <= par ? 3 : moves <= par + 2 ? 2 : 1;
  int get score => max(100, 1000 - max(0, moves - par) * 60).toInt();
  int get planningMetric =>
      (100 - max(0, moves - par) * 10).clamp(30, 100).toInt();

  static int sizeForLevel(int level) {
    if (level <= 3) return 5;
    if (level <= 10) return 6;
    if (level <= 25) return 7;
    return 8;
  }

  static int minParForLevel(int level) => min(2 + (level + 2) ~/ 6, 9);

  factory IceSlideEngine.forLevel(int level, {int? seed}) {
    final safeLevel = max(1, level).toInt();
    final size = sizeForLevel(safeLevel);
    final wanted = minParForLevel(safeLevel);
    final random = Random(seed ?? safeLevel * 6007 + 3);
    final cells = size * size;
    IceSlideEngine? best;

    for (var attempt = 0; attempt < 400; attempt++) {
      final density = .14 + random.nextDouble() * .1;
      final blocks = <int>{
        for (var i = 0; i < cells; i++)
          if (random.nextDouble() < density) i,
      };
      final free = [for (var i = 0; i < cells; i++) if (!blocks.contains(i)) i];
      if (free.length < cells ~/ 2) continue;
      final start = free[random.nextInt(free.length)];
      final distances = _distances(size, blocks, start);
      if (distances.length < 4) continue;
      final farthest = distances.values.reduce(max);
      // Prefer the wanted depth; a deeper route stays inside +2 of it.
      final targetDepth = min(farthest, wanted + 2);
      final goals = [
        for (final entry in distances.entries)
          if (entry.value == targetDepth && entry.key != start) entry.key,
      ]..sort();
      if (goals.isEmpty) continue;
      final goal = goals[random.nextInt(goals.length)];
      final candidate = IceSlideEngine._(level: safeLevel, size: size,
        blocks: blocks, start: start, goal: goal, par: targetDepth);
      if (best == null || candidate.par > best.par) best = candidate;
      if (targetDepth >= wanted) return candidate;
    }
    return best ?? _fallback(safeLevel, size);
  }

  /// A fixed solvable board in case generation never meets the depth.
  static IceSlideEngine _fallback(int level, int size) {
    final blocks = {size + 2};
    final start = 0;
    final distances = _distances(size, blocks, start);
    final goal = distances.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return IceSlideEngine._(level: level, size: size, blocks: blocks,
      start: start, goal: goal.key, par: goal.value);
  }

  static int? stopFrom(int size, Set<int> blocks, int from,
      SlideDirection direction) {
    var row = from ~/ size;
    var column = from % size;
    final (dr, dc) = switch (direction) {
      SlideDirection.up => (-1, 0),
      SlideDirection.right => (0, 1),
      SlideDirection.down => (1, 0),
      SlideDirection.left => (0, -1),
    };
    var moved = false;
    while (true) {
      final nr = row + dr;
      final nc = column + dc;
      if (nr < 0 || nc < 0 || nr >= size || nc >= size) break;
      if (blocks.contains(nr * size + nc)) break;
      row = nr;
      column = nc;
      moved = true;
    }
    return moved ? row * size + column : null;
  }

  static Map<int, int> _distances(int size, Set<int> blocks, int start) {
    final distance = <int, int>{start: 0};
    final queue = Queue<int>()..add(start);
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      for (final direction in SlideDirection.values) {
        final stop = stopFrom(size, blocks, cell, direction);
        if (stop == null || distance.containsKey(stop)) continue;
        distance[stop] = distance[cell]! + 1;
        queue.add(stop);
      }
    }
    return distance;
  }

  /// Cells the puck would cross for [direction], excluding its start.
  int slideLength(SlideDirection direction) {
    final stop = stopFrom(size, blocks, _position, direction);
    if (stop == null) return 0;
    final dr = (stop ~/ size - _position ~/ size).abs();
    final dc = (stop % size - _position % size).abs();
    return dr + dc;
  }

  SlideResult slide(SlideDirection direction) {
    if (_completed) return SlideResult.ignored;
    final stop = stopFrom(size, blocks, _position, direction);
    if (stop == null) return SlideResult.ignored;
    _history.add(_position);
    _position = stop;
    moves++;
    if (_position == goal) {
      _completed = true;
      return SlideResult.completed;
    }
    return SlideResult.moved;
  }

  /// Steps back one slide. Undo still counts toward the move total.
  bool undo() {
    if (!canUndo) return false;
    _position = _history.removeLast();
    return true;
  }
}
