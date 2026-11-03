import 'dart:math';

enum RailAction { switched, advanced, completed, collision, ignored }

/// Switch one train to a longer bypass so both trains clear the junction safely.
class RailRouterEngine {
  RailRouterEngine._(this.level, this.baseArrival, this.detourDelay);
  final int level;
  final int baseArrival;
  final int detourDelay;
  final List<bool> diverted = [false, false];
  final List<bool> passed = [false, false];
  int time = 0;
  bool isCompleted = false;
  bool isFailed = false;
  int get score => max(100, 1000 - time * 35 - diverted.where((x) => x).length * 40).toInt();
  List<int> get arrivals => [
    for (var train = 0; train < 2; train++)
      baseArrival + (diverted[train] ? detourDelay : 0),
  ];
  List<int> get countdowns => [
    for (var train = 0; train < 2; train++) max(0, arrivals[train] - time).toInt(),
  ];

  factory RailRouterEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    return RailRouterEngine._(safe, 3 + (safe - 1) % 4,
      min(4, 2 + (safe - 1) ~/ 12).toInt());
  }

  RailAction toggle(int train) {
    if (isCompleted || isFailed || train < 0 || train >= 2 || passed[train] ||
        time >= baseArrival) {
      return RailAction.ignored;
    }
    diverted[train] = !diverted[train];
    return RailAction.switched;
  }

  RailAction advance() {
    if (isCompleted || isFailed) return RailAction.ignored;
    time++;
    final arriving = [for (var train = 0; train < 2; train++)
      if (!passed[train] && arrivals[train] == time) train];
    if (arriving.length > 1) {
      isFailed = true;
      return RailAction.collision;
    }
    for (final train in arriving) { passed[train] = true; }
    isCompleted = passed.every((value) => value);
    return isCompleted ? RailAction.completed : RailAction.advanced;
  }
}
