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
            : min<int>(256, 16 << min<int>(4, (floor - 1) ~/ 6));
        return GameObjective(
          title: 'Reach the $target tile',
          instruction: 'Swipe to merge equal tiles until you create $target.',
          target: target,
          unit: 'Highest tile',
        );
      case 'numberSequence':
        return const GameObjective(
          title: 'Solve 2 of 3 patterns',
          instruction: 'Choose the missing number. Get at least 2 answers right.',
          target: 2,
          unit: 'Correct answers',
        );
      default:
        throw ArgumentError.value(gameId, 'gameId', 'Unknown game objective');
    }
  }
}
