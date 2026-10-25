import 'dart:collection';

/// Grid-based traffic jam puzzle. Each car slides only on its own axis.
/// Car zero is the red escape car. Position is its top-left cell.
class ParkingCar {
  const ParkingCar({
    required this.id,
    required this.row,
    required this.column,
    required this.length,
    required this.horizontal,
  });

  final int id;
  final int row;
  final int column;
  final int length;
  final bool horizontal;

  ParkingCar at(int row, int column) => ParkingCar(
    id: id, row: row, column: column, length: length,
    horizontal: horizontal,
  );
}

class ParkingEscapeSession {
  ParkingEscapeSession({required this.seed})
      : cars = List<ParkingCar>.from(_layouts[_positiveModulo(seed, _layouts.length)]);

  static const size = 6;
  final int seed;
  final List<ParkingCar> cars;
  int moves = 0;

  static int _positiveModulo(int a, int n) => ((a % n) + n) % n;

  // Authored, guaranteed-solvable layouts. Solver tests validate all stages.
  static const _layouts = <List<ParkingCar>>[
    [
      ParkingCar(id: 0, row: 2, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 1, row: 1, column: 3, length: 2, horizontal: false),
      ParkingCar(id: 2, row: 0, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 3, row: 5, column: 4, length: 2, horizontal: true),
    ],
    [
      ParkingCar(id: 0, row: 2, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 1, row: 0, column: 4, length: 3, horizontal: false),
      ParkingCar(id: 2, row: 4, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 3, row: 0, column: 0, length: 2, horizontal: true),
    ],
    [
      ParkingCar(id: 0, row: 2, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 1, row: 1, column: 2, length: 2, horizontal: false),
      ParkingCar(id: 2, row: 1, column: 4, length: 2, horizontal: false),
      ParkingCar(id: 3, row: 4, column: 0, length: 2, horizontal: true),
    ],
    [
      ParkingCar(id: 0, row: 2, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 1, row: 2, column: 3, length: 3, horizontal: false),
      ParkingCar(id: 2, row: 0, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 3, row: 4, column: 4, length: 2, horizontal: true),
    ],
    [
      ParkingCar(id: 0, row: 2, column: 1, length: 2, horizontal: true),
      ParkingCar(id: 1, row: 1, column: 4, length: 3, horizontal: false),
      ParkingCar(id: 2, row: 0, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 3, row: 5, column: 0, length: 2, horizontal: true),
    ],
    [
      ParkingCar(id: 0, row: 2, column: 0, length: 2, horizontal: true),
      ParkingCar(id: 1, row: 0, column: 3, length: 3, horizontal: false),
      ParkingCar(id: 2, row: 3, column: 3, length: 2, horizontal: true),
      ParkingCar(id: 3, row: 5, column: 0, length: 2, horizontal: true),
    ],
  ];

  ParkingCar car(int id) => cars.firstWhere((c) => c.id == id);

  /// Reaching the right board edge unlocks the exit.
  bool get complete => car(0).column + car(0).length == size;

  bool _isLegal(List<ParkingCar> board) {
    final occupied = <int>{};
    for (final car in board) {
      if (car.length < 2 || car.row < 0 || car.column < 0 ||
          car.row + (car.horizontal ? 1 : car.length) > size ||
          car.column + (car.horizontal ? car.length : 1) > size) {
        return false;
      }
      for (var i = 0; i < car.length; i++) {
        final row = car.row + (car.horizontal ? 0 : i);
        final col = car.column + (car.horizontal ? i : 0);
        if (!occupied.add(row * size + col)) return false;
      }
    }
    return true;
  }

  bool get boardIsValid => _isLegal(cars);

  /// Move one grid square along the car's own axis.
  /// Invalid gestures must not count as moves.
  bool slide(int id, int direction) {
    if (complete || direction != -1 && direction != 1) return false;
    final index = cars.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    final current = cars[index];
    final next = current.at(
      current.row + (current.horizontal ? 0 : direction),
      current.column + (current.horizontal ? direction : 0),
    );
    final proposal = List<ParkingCar>.from(cars)..[index] = next;
    if (!_isLegal(proposal)) return false;
    cars[index] = next;
    moves++;
    return true;
  }

  /// Breadth-first search; useful for level validation and an eventual hint.
  /// Returns a shortest sequence of (car ID, +/- one-square displacement).
  List<(int, int)>? shortestSolution({int maxStates = 35000}) {
    final initial = List<ParkingCar>.from(cars);
    String key(List<ParkingCar> board) =>
        board.map((c) => '${c.id}:${c.row},${c.column}').join(';');
    final root = key(initial);
    final queue = Queue<List<ParkingCar>>()..add(initial);
    final seen = <String>{root};
    final parents = <String, (String, (int, int))>{};
    while (queue.isNotEmpty && seen.length <= maxStates) {
      final board = queue.removeFirst();
      final stateKey = key(board);
      final target = board.firstWhere((c) => c.id == 0);
      if (target.column + target.length == size) {
        final path = <(int, int)>[];
        var cursor = stateKey;
        while (cursor != root) {
          final parent = parents[cursor]!;
          path.add(parent.$2);
          cursor = parent.$1;
        }
        return path.reversed.toList();
      }
      for (var i = 0; i < board.length; i++) {
        for (final delta in const [-1, 1]) {
          final car = board[i];
          final updated = car.at(
            car.row + (car.horizontal ? 0 : delta),
            car.column + (car.horizontal ? delta : 0),
          );
          final next = List<ParkingCar>.from(board)..[i] = updated;
          if (!_isLegal(next)) continue;
          final nextKey = key(next);
          if (!seen.add(nextKey)) continue;
          parents[nextKey] = (stateKey, (car.id, delta));
          queue.add(next);
        }
      }
    }
    return null;
  }
}
