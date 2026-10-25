/// Three-peg Tower of Hanoi. Disks are numbered from 1 (smallest) upwards.
/// Each seeded round is provably solvable in 2^diskCount - 1 moves.
class DiskTowersSession {
  DiskTowersSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0) {
    _startRound();
  }

  final int seed;
  final int roundCount;
  int round = 0;
  int totalMoves = 0;
  int roundMoves = 0;
  int invalidMoves = 0;
  int? selectedPeg;
  late int diskCount;
  late int startPeg;
  late int goalPeg;
  late List<List<int>> pegs;

  bool get complete => round == roundCount;
  int get optimalMoves => (1 << diskCount) - 1;
  int get remainingDisks => complete ? 0 : diskCount - pegs[goalPeg].length;

  /// Derive configuration from seed and round; never use global randomness.
  void _startRound() {
    if (complete) return;
    diskCount = round == 0 ? 3 : round == 1 ? 3 : 4;
    startPeg = (seed.abs() + round) % 3;
    goalPeg = (startPeg + 1 + ((seed.abs() ~/ 3 + round) % 2)) % 3;
    pegs = [<int>[], <int>[], <int>[]];
    pegs[startPeg] = [for (var disk = diskCount; disk >= 1; disk--) disk];
    selectedPeg = null;
    roundMoves = 0;
  }

  bool get solved => !complete && pegs[goalPeg].length == diskCount;

  /// Two taps: select source, then destination.
  /// A second tap on the source cancels selection.
  /// Illegal transfers are rejected without changing a single disk.
  bool tapPeg(int peg) {
    if (complete || peg < 0 || peg >= 3) return false;
    if (selectedPeg == null) {
      if (pegs[peg].isEmpty) return false;
      selectedPeg = peg;
      return true;
    }
    final source = selectedPeg!;
    if (source == peg) {
      selectedPeg = null;
      return true;
    }
    if (pegs[source].isEmpty ||
        (pegs[peg].isNotEmpty && pegs[peg].last < pegs[source].last)) {
      invalidMoves++;
      return false;
    }
    final moving = pegs[source].removeLast();
    pegs[peg].add(moving);
    selectedPeg = null;
    roundMoves++;
    totalMoves++;
    if (solved) {
      round++;
      _startRound();
    }
    return true;
  }

  /// Non-mutating search-independent oracle for the optimal legal solution.
  /// Useful for tests and future optional hint UI.
  List<(int, int)> optimalRoute() {
    if (complete) return const [];
    final auxiliary = ({0, 1, 2}..removeAll({startPeg, goalPeg})).single;
    final moves = <(int, int)>[];
    void visit(int n, int from, int to, int spare) {
      if (n == 0) return;
      visit(n - 1, from, spare, to);
      moves.add((from, to));
      visit(n - 1, spare, to, from);
    }
    visit(diskCount, startPeg, goalPeg, auxiliary);
    return moves;
  }
}
