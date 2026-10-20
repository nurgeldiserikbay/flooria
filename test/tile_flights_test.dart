import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/game/merge_2048.dart';
import 'package:flooria/ui/sliding_2048_board.dart';

void main() {
  test('two identical adjacent tiles fly into the same destination', () {
    final cells = List<int>.filled(16, 0);
    cells[0] = 2;
    cells[1] = 2;
    final flights = planTileFlights(cells, MoveDirection.left);
    expect(flights.length, 2);
    expect(flights.map((t) => t.to).toSet(), {0});
  });
  test('no double merge for triple tiles', () {
    final cells = List<int>.filled(16, 0);
    cells[0] = 2;
    cells[1] = 2;
    cells[2] = 2;
    final flights = planTileFlights(cells, MoveDirection.left);
    expect(flights.map((f) => f.to).toList(), [0, 0, 1]);
  });
  test('vertical swipe moves tiles to their correct rows', () {
    final cells = List<int>.filled(16, 0);
    cells[0] = 4;
    cells[8] = 4;
    final flights = planTileFlights(cells, MoveDirection.down);
    expect(flights.map((f) => f.to).toSet(), {12});
  });
  test('each distinct tile keeps its original value in flight', () {
    final cells = List<int>.filled(16, 0);
    cells[0] = 2;
    cells[3] = 8;
    final flights = planTileFlights(cells, MoveDirection.left);
    expect(flights.map((f) => f.value).toList(), [2, 8]);
    expect(flights.map((f) => f.to).toList(), [0, 1]);
  });
}
