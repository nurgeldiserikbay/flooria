import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/merge_2048.dart';

void main() {
  for (final direction in MoveDirection.values) {
    test('2048 supports ${direction.name} swipe direction', () {
      final game = Merge2048(seed: 11);
      game.cells.fillRange(0, 16, 0);
      final positions = switch (direction) {
        MoveDirection.left => [2, 3],
        MoveDirection.right => [0, 1],
        MoveDirection.up => [8, 12],
        MoveDirection.down => [0, 4],
      };
      for (final position in positions) {
        game.cells[position] = 2;
      }
      expect(game.move(direction), isTrue);
      final destination = switch (direction) {
        MoveDirection.left => 0,
        MoveDirection.right => 3,
        MoveDirection.up => 0,
        MoveDirection.down => 12,
      };
      expect(game.cells[destination], 4);
      expect(game.score, 4);
    });
  }
}
