import 'dart:math';

enum TowerMove { selected, deselected, moved, blocked, completed, ignored }

/// Rules for a three-peg disk transfer puzzle.
class TowerShiftEngine {
  TowerShiftEngine._(this.level, this.disks)
      : pegs = [
          List<int>.generate(disks, (i) => disks - i),
          <int>[],
          <int>[],
        ];

  final int level;
  final int disks;
  /// Each peg is stored bottom-to-top; the last value is its top disk.
  final List<List<int>> pegs;
  int? selectedPeg;
  int moves = 0;
  bool isCompleted = false;

  int get par => (1 << disks) - 1;
  int get score => max(100, 1000 - max(0, moves - par) * 25).toInt();
  int get planningMetric => (100 - max(0, moves - par) * 8).clamp(35, 100).toInt();

  factory TowerShiftEngine.forLevel(int level) {
    final safeLevel = max(1, level).toInt();
    final disks = min(3 + (safeLevel - 1) ~/ 2, 7).toInt();
    return TowerShiftEngine._(safeLevel, disks);
  }

  TowerMove tapPeg(int peg) {
    if (isCompleted || peg < 0 || peg >= pegs.length) return TowerMove.ignored;
    final source = selectedPeg;
    if (source == null) {
      if (pegs[peg].isEmpty) return TowerMove.ignored;
      selectedPeg = peg;
      return TowerMove.selected;
    }
    if (source == peg) {
      selectedPeg = null;
      return TowerMove.deselected;
    }
    final disk = pegs[source].last;
    if (pegs[peg].isNotEmpty && pegs[peg].last < disk) {
      return TowerMove.blocked;
    }
    pegs[source].removeLast();
    pegs[peg].add(disk);
    selectedPeg = null;
    moves++;
    if (peg == 2 && pegs[2].length == disks) {
      isCompleted = true;
      return TowerMove.completed;
    }
    return TowerMove.moved;
  }
}
