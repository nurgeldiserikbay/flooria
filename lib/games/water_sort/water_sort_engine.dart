import 'dart:math';

enum PourAction { selected, poured, completed, blocked, ignored }

/// Sort coloured layers into uniform tubes. Tube lists are stored bottom-up.
class WaterSortEngine {
  WaterSortEngine._(this.level, this.colors, this.tubes);

  static const int capacity = 4;
  final int level;
  final int colors;
  final List<List<int>> tubes;
  int? selectedTube;
  int moves = 0;
  bool isCompleted = false;
  int get score => max(100, 1000 - moves * 16).toInt();

  factory WaterSortEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final colors = min(3 + (safe - 1) ~/ 18, 5).toInt();
    final random = Random(safe * 37337 + 53);
    final balls = [for (var color = 0; color < colors; color++)
      for (var i = 0; i < capacity; i++) color]..shuffle(random);
    final tubes = <List<int>>[];
    for (var tube = 0; tube < colors + 2; tube++) {
      final start = tube * capacity;
      tubes.add(start >= balls.length
        ? <int>[] : balls.skip(start).take(capacity).toList());
    }
    if (_isSolved(tubes)) {
      final first = tubes[0].removeLast();
      final second = tubes[1].removeLast();
      tubes[0].add(second);
      tubes[1].add(first);
    }
    return WaterSortEngine._(safe, colors, tubes);
  }

  PourAction tapTube(int tubeIndex) {
    if (isCompleted || tubeIndex < 0 || tubeIndex >= tubes.length) {
      return PourAction.ignored;
    }
    final selected = selectedTube;
    if (selected == null) {
      if (tubes[tubeIndex].isEmpty) return PourAction.ignored;
      selectedTube = tubeIndex;
      return PourAction.selected;
    }
    if (selected == tubeIndex) {
      selectedTube = null;
      return PourAction.ignored;
    }
    final source = tubes[selected];
    final destination = tubes[tubeIndex];
    if (source.isEmpty || destination.length >= capacity ||
        (destination.isNotEmpty && destination.last != source.last)) {
      if (destination.isEmpty && source.isNotEmpty) {
        selectedTube = tubeIndex;
        return PourAction.selected;
      }
      return PourAction.blocked;
    }
    final color = source.last;
    var amount = 0;
    while (source.isNotEmpty && source.last == color &&
        destination.length < capacity) {
      destination.add(source.removeLast());
      amount++;
    }
    if (amount == 0) return PourAction.blocked;
    selectedTube = null;
    moves++;
    isCompleted = _isSolved(tubes);
    return isCompleted ? PourAction.completed : PourAction.poured;
  }

  static bool _isSolved(List<List<int>> tubes) => tubes.every((tube) =>
      tube.isEmpty || (tube.length == capacity && tube.every((color) => color == tube.first)));
}
