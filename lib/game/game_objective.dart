import 'dart:math';

/// Explicit, reusable objectives shown by the tower and by every game screen.
class GameObjective {
  final String title;
  final String instruction;
  final int target;
  final String unit;

  const GameObjective({
    required this.title,
    required this.instruction,
    required this.target,
    required this.unit,
  });

  bool isComplete(int progress) => progress >= target;

  double completion(int progress) => (progress / target).clamp(0.0, 1.0);
}

class ObjectiveCatalog {
  const ObjectiveCatalog();

  GameObjective forGame(String gameId, {int? floor}) {
    switch (gameId) {
      case 'merge2048':
        final target = floor == null
            ? 2048
            : 128 << min<int>(4, (floor - 1) ~/ 12);
        return GameObjective(
          title: 'Reach the $target tile',
          instruction: 'Swipe to merge equal tiles until you create $target.',
          target: target,
          unit: 'Highest tile',
        );
      case 'numberSequence':
        final required = floor != null && floor >= 14 ? 3 : 2;
        return GameObjective(
          title: 'Solve $required of 3 patterns',
          instruction: 'Find the missing number in three different puzzles.',
          target: required,
          unit: 'Correct answers',
        );
      case 'memory':
        return const GameObjective(
          title: 'Find all 6 pairs',
          instruction: 'Turn over two cards and remember their symbols.',
          target: 6,
          unit: 'Matched pairs',
        );
      case 'colorMatch':
        return const GameObjective(
          title: 'Spot 4 of 5 differences',
          instruction: 'Find the one tile with a different shade.',
          target: 4,
          unit: 'Correct choices',
        );
      case 'speed':
        return const GameObjective(
          title: 'Find numbers 1 to 9',
          instruction: 'Tap the shuffled numbers in ascending order.',
          target: 9,
          unit: 'Numbers found',
        );
      case 'logic':
        return const GameObjective(
          title: 'Turn off every light',
          instruction: 'Tap a cell to change it and its neighbors.',
          target: 9,
          unit: 'Dark cells',
        );
      case 'pattern':
        return const GameObjective(
          title: 'Repeat 3 light patterns',
          instruction: 'Watch the pads flash, then repeat in the same order.',
          target: 3,
          unit: 'Patterns recalled',
        );
      case 'fifteen':
        return const GameObjective(
          title: 'Arrange all fifteen tiles',
          instruction: 'Slide numbered tiles into the empty space to restore order.',
          target: 15,
          unit: 'Ordered tiles',
        );
      case 'maze':
        return const GameObjective(
          title: 'Find the maze exit',
          instruction: 'Navigate through the maze to reach the golden star.',
          target: 1,
          unit: 'Exit reached',
        );
      default:
        throw ArgumentError.value(gameId, 'gameId', 'Unknown game objective');
    }
  }
}
