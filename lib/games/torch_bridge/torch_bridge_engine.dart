/// Four travelers must cross a dark bridge. At most two can move with the
/// torch; the duration of a crossing is the slower traveler's time.
///
/// All stages use an exact shortest-path solver to set a fair time budget.
class TorchBridgeSession {
  TorchBridgeSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _setStage();
  }

  static const travelerCount = 4;
  static const allAcross = (1 << travelerCount) - 1;
  static const _times = <List<int>>[
    [1, 2, 5, 10],
    [1, 3, 6, 8],
    [2, 3, 7, 12],
    [1, 4, 6, 9],
    [2, 4, 5, 11],
    [1, 2, 6, 12],
  ];

  final int seed;
  final int roundCount;

  int round = 0;
  int elapsed = 0;
  int crossings = 0;
  int mistakes = 0;
  int acrossMask = 0;
  bool torchAcross = false;

  late List<int> travelerTimes;
  late int timeLimit;
  final Set<int> selected = {};

  bool get complete => round >= roundCount;
  bool get solved => acrossMask == allAcross && torchAcross;
  bool get outOfTime => elapsed > timeLimit;
  bool get canCross => !complete && !solved && !outOfTime &&
      selected.isNotEmpty && selected.length <= 2 &&
      selected.every(isOnTorchSide);

  bool isAcross(int traveler) =>
      (acrossMask & (1 << traveler)) != 0;

  bool isOnTorchSide(int traveler) =>
      traveler >= 0 && traveler < travelerCount &&
      isAcross(traveler) == torchAcross;

  void _setStage() {
    if (complete) return;
    final variant = ((seed % _times.length) + round + _times.length) % _times.length;
    travelerTimes = List<int>.unmodifiable(_times[variant]);
    acrossMask = 0;
    torchAcross = false;
    elapsed = 0;
    crossings = 0;
    selected.clear();
    timeLimit = shortestRemainingTime();
  }

  /// Selected passengers cannot be on the far side of the current torch.
  bool toggle(int traveler) {
    if (complete || solved || outOfTime || !isOnTorchSide(traveler)) {
      return false;
    }
    if (selected.contains(traveler)) {
      selected.remove(traveler);
      return true;
    }
    if (selected.length == 2) return false;
    selected.add(traveler);
    return true;
  }

  /// Returns false for invalid moves, retaining the state.
  /// Time overflow is a terminal failed attempt until restart.
  bool cross() {
    if (!canCross) return false;
    final duration = selected.map((id) => travelerTimes[id])
        .reduce((a, b) => a > b ? a : b);
    for (final id in selected) {
      acrossMask ^= 1 << id;
    }
    elapsed += duration;
    crossings++;
    torchAcross = !torchAcross;
    selected.clear();
    if (outOfTime) mistakes++;
    return true;
  }

  /// Move to the next seeded challenge only after a winning bridge state.
  bool nextRound() {
    if (complete || !solved || outOfTime) return false;
    round++;
    _setStage();
    return true;
  }

  /// Exact Dijkstra on at most 32 states, used to guarantee the budget.
  /// State bit 4 is the torch bank; bits 0..3 are traveler banks.
  int shortestRemainingTime() {
    final start = acrossMask | (torchAcross ? 16 : 0);
    const count = 32;
    final distances = List<int>.filled(count, 1 << 30);
    final visited = List<bool>.filled(count, false);
    distances[start] = 0;
    for (var iteration = 0; iteration < count; iteration++) {
      var state = -1;
      for (var i = 0; i < count; i++) {
        if (!visited[i] && (state == -1 || distances[i] < distances[state])) {
          state = i;
        }
      }
      if (state == -1 || distances[state] == 1 << 30) break;
      if (state == (allAcross | 16)) return distances[state];
      visited[state] = true;
      final torch = (state & 16) != 0;
      final eligible = <int>[
        for (var i = 0; i < travelerCount; i++)
          if (((state & (1 << i)) != 0) == torch) i,
      ];
      for (var a = 0; a < eligible.length; a++) {
        for (var b = a; b < eligible.length; b++) {
          if (b == a + 0) {
            // Crossing with one passenger is allowed.
          }
          final idA = eligible[a];
          final mask = (1 << idA) |
              (a == b ? 0 : 1 << eligible[b]);
          final cost = a == b
              ? travelerTimes[idA]
              : (travelerTimes[idA] > travelerTimes[eligible[b]]
                  ? travelerTimes[idA] : travelerTimes[eligible[b]]);
          final next = (state ^ mask) ^ 16;
          if (distances[state] + cost < distances[next]) {
            distances[next] = distances[state] + cost;
          }
        }
      }
    }
    throw StateError('Torch crossing has no solution');
  }
}
