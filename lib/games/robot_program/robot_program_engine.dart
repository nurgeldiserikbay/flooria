import 'dart:math';

enum RobotCommand { forward, turnLeft, turnRight }
enum ProgramRun { ran, incomplete, crashed, completed, ignored }

/// Build a short command list, then run the robot through the maze.
class RobotProgramEngine {
  RobotProgramEngine._(this.level, this.path, this.walls, this.start, this.goal,
      this.commandLimit);

  static const int side = 5;
  final int level;
  final List<int> path;
  final Set<int> walls;
  final int start;
  final int goal;
  final int commandLimit;
  final List<RobotCommand> program = [];
  int robot = 0;
  int heading = 0; // north, east, south, west
  int runs = 0;
  bool isCompleted = false;
  bool lastRunCrashed = false;
  int get score => max(100, 1000 - runs * 45 - program.length * 8).toInt();

  factory RobotProgramEngine.forLevel(int level) {
    final safe = max(1, level).toInt();
    final random = Random(safe * 28411 + 83);
    final moves = <int>[...List<int>.filled(side - 1, 0), ...List<int>.filled(side - 1, 1)]
      ..shuffle(random);
    var row = side - 1, col = 0;
    final path = <int>[row * side + col];
    for (final move in moves) {
      if (move == 0) {
        row--;
      } else {
        col++;
      }
      path.add(row * side + col);
    }
    final walls = {for (var cell = 0; cell < side * side; cell++)
      if (!path.contains(cell)) cell};
    final solution = <RobotCommand>[];
    var heading = 0;
    for (var i = 1; i < path.length; i++) {
      final previous = path[i - 1], next = path[i];
      final direction = next == previous - side ? 0 : 1;
      final turn = (direction - heading + 4) % 4;
      if (turn == 1) { solution.add(RobotCommand.turnRight); }
      if (turn == 3) { solution.add(RobotCommand.turnLeft); }
      if (turn == 2) {
        solution.add(RobotCommand.turnRight);
        solution.add(RobotCommand.turnRight);
      }
      if (turn != 0) heading = direction;
      solution.add(RobotCommand.forward);
    }
    final engine = RobotProgramEngine._(safe, path, walls, path.first, path.last,
      solution.length + 2);
    engine.robot = engine.start;
    return engine;
  }

  bool add(RobotCommand command) {
    if (isCompleted || program.length >= commandLimit) return false;
    program.add(command);
    lastRunCrashed = false;
    return true;
  }

  bool removeLast() {
    if (program.isEmpty || isCompleted) return false;
    program.removeLast();
    lastRunCrashed = false;
    return true;
  }

  void clear() {
    if (isCompleted) return;
    program.clear();
    robot = start;
    heading = 0;
    lastRunCrashed = false;
  }

  ProgramRun run() {
    if (isCompleted || program.isEmpty) return ProgramRun.ignored;
    runs++;
    robot = start;
    heading = 0;
    lastRunCrashed = false;
    for (final command in program) {
      switch (command) {
        case RobotCommand.turnLeft:
          heading = (heading + 3) % 4;
          break;
        case RobotCommand.turnRight:
          heading = (heading + 1) % 4;
          break;
        case RobotCommand.forward:
          final row = robot ~/ side, col = robot % side;
          const rowDelta = [-1, 0, 1, 0];
          const colDelta = [0, 1, 0, -1];
          final nextRow = row + rowDelta[heading];
          final nextCol = col + colDelta[heading];
          if (nextRow < 0 || nextRow >= side || nextCol < 0 || nextCol >= side ||
              walls.contains(nextRow * side + nextCol)) {
            lastRunCrashed = true;
            return ProgramRun.crashed;
          }
          robot = nextRow * side + nextCol;
          if (robot == goal) {
            isCompleted = true;
            return ProgramRun.completed;
          }
          break;
      }
    }
    return ProgramRun.incomplete;
  }
}
