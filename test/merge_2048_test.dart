import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/merge_2048.dart';

void main() {
  test('2048 starts with two numbered tiles', () {
    final game = Merge2048(seed: 7);
    expect(game.cells.where((n) => n != 0).length, 2);
    expect(game.score, 0);
  });

  test('moving an equal pair merges once', () {
    final game = Merge2048(seed: 5);
    game.cells.fillRange(0, 16, 0);
    game.cells[0] = 2;
    game.cells[1] = 2;
    expect(game.move(MoveDirection.left), isTrue);
    expect(game.cells[0], 4);
    expect(game.score, 4);
    expect(game.moves, 1);
  });

  test('blocked board has no legal moves', () {
    final game = Merge2048(seed: 5);
    for (var i = 0; i < 16; i++) {
      game.cells[i] = (i + i ~/ 4).isEven ? 2 : 4;
    }
    expect(game.canMove, isFalse);
  });
}
