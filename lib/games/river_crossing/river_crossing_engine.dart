import 'dart:math';

/// Boat operator is always aboard. Left bank is 0, right bank is 1.
/// Dangerous pairs must not be left together without the operator.
class RiverCrossingSession {
  RiverCrossingSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _newRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int moves = 0;
  int totalMoves = 0;
  int invalidMoves = 0;
  int boatBank = 0;
  int rightMask = 0;
  final Set<int> selected = {};

  late List<String> passengers;
  late List<(int, int)> forbidden;
  late int capacity;
  late int optimalMoves;

  bool get complete => round >= roundCount;
  bool get wonRound => !complete &&
      rightMask == (1 << passengers.length) - 1 && boatBank == 1;

  bool onRight(int passenger) => (rightMask & (1 << passenger)) != 0;
  int bankOf(int passenger) => onRight(passenger) ? 1 : 0;

  bool safe(int mask, int operatorBank) {
    for (final pair in forbidden) {
      final a = (mask >> pair.$1) & 1;
      final b = (mask >> pair.$2) & 1;
      if (a == b && a != operatorBank) return false;
    }
    return true;
  }

  /// BFS shortest solution, moving the operator plus up to [capacity] items.
  /// An empty boat trip is allowed, but only if both banks remain safe.
  List<List<int>>? shortestPath({int? fromMask, int? fromBank}) {
    final startMask = fromMask ?? rightMask;
    final startBank = fromBank ?? boatBank;
    final goal = (1 << passengers.length) - 1;
    final queue = <(int, int, List<List<int>>)>[(startMask, startBank, [])];
    final visited = <String>{'$startMask:$startBank'};
    for (var index = 0; index < queue.length; index++) {
      final current = queue[index];
      if (current.$1 == goal && current.$2 == 1) return current.$3;
      final available = [
        for (var i = 0; i < passengers.length; i++)
          if (((current.$1 >> i) & 1) == current.$2) i,
      ];
      for (var subset = 0; subset < (1 << available.length); subset++) {
        if (_bitCount(subset) > capacity) continue;
        final cargo = <int>[];
        var nextMask = current.$1;
        for (var i = 0; i < available.length; i++) {
          if ((subset & (1 << i)) != 0) {
            cargo.add(available[i]);
            nextMask ^= 1 << available[i];
          }
        }
        final nextBank = 1 - current.$2;
        if (!safe(nextMask, nextBank)) continue;
        final key = '$nextMask:$nextBank';
        if (visited.add(key)) {
          queue.add((nextMask, nextBank, [...current.$3, cargo]));
        }
      }
    }
    return null;
  }

  static int _bitCount(int bits) {
    var n = bits;
    var result = 0;
    while (n > 0) {
      result += n & 1;
      n >>= 1;
    }
    return result;
  }

  void _newRound() {
    if (complete) return;
    final random = Random((seed * 65537 + round * 8191) & 0x7fffffff);
    final names = ['Fox', 'Goat', 'Cabbage', 'Rabbit']..shuffle(random);
    final count = round == 0 ? 3 : 4;
    passengers = names.take(count).toList(growable: false);
    capacity = round == 0 ? 1 : 2;
    forbidden = switch (round % 3) {
      0 => [(0, 1), (1, 2)],
      1 => [(0, 1), (1, 2), (2, 3)],
      _ => [(0, 1), (0, 2), (0, 3)],
    };
    rightMask = 0;
    boatBank = 0;
    moves = 0;
    selected.clear();
    final path = shortestPath();
    if (path == null) throw StateError('Generated impossible crossing');
    optimalMoves = path.length;
  }

  /// Selecting passengers never changes their river bank.
  bool toggle(int passenger) {
    if (complete || passenger < 0 || passenger >= passengers.length ||
        bankOf(passenger) != boatBank) return false;
    if (selected.contains(passenger)) {
      selected.remove(passenger);
    } else {
      if (selected.length >= capacity) return false;
      selected.add(passenger);
    }
    return true;
  }

  /// Returns false without mutation if cargo is unsafe or impossible.
  bool cross() {
    if (complete || selected.length > capacity ||
        selected.any((i) => bankOf(i) != boatBank)) return false;
    var mask = rightMask;
    for (final i in selected) {
      mask ^= 1 << i;
    }
    final nextBank = 1 - boatBank;
    if (!safe(mask, nextBank)) {
      invalidMoves++;
      return false;
    }
    rightMask = mask;
    boatBank = nextBank;
    moves++;
    totalMoves++;
    selected.clear();
    if (wonRound) {
      round++;
      _newRound();
    }
    return true;
  }
}
