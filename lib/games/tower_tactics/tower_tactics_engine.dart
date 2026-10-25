import 'dart:math';

/// A compact three-peg planning puzzle with deterministic, reachable boards.
/// Each peg stores disks from bottom to top, so its last item is the top disk.
class TowerTacticsSession {
  TowerTacticsSession({required this.seed, this.roundCount = 4})
      : assert(roundCount > 0) {
    _newRound();
  }

  final int seed;
  final int roundCount;

  int roundsCompleted = 0;
  int round = 1;
  int moves = 0;
  int get roundMoves => _roundMoves;
  bool complete = false;

  late int diskCount;
  late int targetPeg;
  late List<List<int>> _pegs;
  int _roundMoves = 0;

  static const int pegCount = 3;

  /// Immutable copy of the current board for rendering and assertions.
  List<List<int>> get board => [
        for (final peg in _pegs) List<int>.unmodifiable(peg),
      ];

  static bool canPlace(int disk, int? destinationTop) =>
      destinationTop == null || destinationTop > disk;

  int? topDisk(int peg) {
    if (peg < 0 || peg >= pegCount || _pegs[peg].isEmpty) return null;
    return _pegs[peg].last;
  }

  /// Attempts one move. Invalid moves leave the game state unchanged.
  bool move(int from, int to) {
    if (complete || from < 0 || from >= pegCount || to < 0 ||
        to >= pegCount || from == to || _pegs[from].isEmpty) {
      return false;
    }
    final disk = _pegs[from].last;
    final destinationTop = _pegs[to].isEmpty ? null : _pegs[to].last;
    if (!canPlace(disk, destinationTop)) return false;

    _pegs[from].removeLast();
    _pegs[to].add(disk);
    moves++;
    _roundMoves++;
    if (_pegs[targetPeg].length == diskCount) {
      roundsCompleted++;
      if (roundsCompleted == roundCount) {
        complete = true;
      } else {
        _newRound();
      }
    }
    return true;
  }

  void _newRound() {
    if (roundsCompleted >= roundCount) {
      complete = true;
      return;
    }
    round = roundsCompleted + 1;
    _roundMoves = 0;
    final random = Random((seed * 65537 + round * 7919) & 0x7fffffff);
    diskCount = min(6, 3 + (round - 1) ~/ 2).toInt();
    final source = random.nextInt(pegCount);
    targetPeg = (source + 1 + random.nextInt(pegCount - 1)) % pegCount;
    _pegs = List.generate(pegCount, (_) => <int>[]);
    _pegs[source].addAll(List.generate(diskCount, (index) => diskCount - index));

    // Scrambling starts from a valid canonical stack, so reversing the moves
    // always returns to a known state. Avoid undoing the previous scramble move.
    final scrambleMoves = diskCount * 3 + round;
    int? previousFrom;
    int? previousTo;
    for (var step = 0; step < scrambleMoves; step++) {
      final legal = <(int, int)>[];
      for (var from = 0; from < pegCount; from++) {
        if (_pegs[from].isEmpty) continue;
        for (var to = 0; to < pegCount; to++) {
          if (from == to || (from == previousTo && to == previousFrom)) continue;
          final moving = _pegs[from].last;
          final top = _pegs[to].isEmpty ? null : _pegs[to].last;
          if (canPlace(moving, top)) {
            legal.add((from, to));
          }
        }
      }
      final (from, to) = legal[random.nextInt(legal.length)];
      _pegs[to].add(_pegs[from].removeLast());
      previousFrom = from;
      previousTo = to;
    }
    // A board that already matches the goal is technically solved, so make
    // another deterministic legal move if the scramble happened to do that.
    if (_pegs[targetPeg].length == diskCount) {
      final from = targetPeg;
      final disk = _pegs[from].removeLast();
      final to = (targetPeg + 1) % pegCount;
      _pegs[to].add(disk);
    }
  }
}
