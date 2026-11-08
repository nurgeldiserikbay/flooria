import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/core/neuron_progression.dart';
import 'package:flooria/games/continuous_maze/continuous_maze_engine.dart';

void main() {
  group('ContinuousMazeEngine', () {
    test('is registered as a standalone game and an unlockable neuron', () {
      expect(GameRegistry.byId('continuous_maze').title, 'One Stroke');
      final node = NeuronMapGraph.byId('node_14');
      expect(node.moduleId, 'continuous_maze');
      expect(NeuronMapGraph.availability(node, {'node_13'}),
          NeuronAvailability.open);
    });

    test('seeded mazes are repeatable, connected trees with a valid exit path', () {
      final first = ContinuousMazeEngine.forLevel(17, seed: 812);
      final second = ContinuousMazeEngine.forLevel(17, seed: 812);

      expect(first.side, 6);
      expect(first.goal, second.goal);
      expect(first.solution, second.solution);
      expect(first.solution.first, first.start);
      expect(first.solution.last, first.goal);
      expect(first.solution.length, greaterThan(2));
      for (var i = 1; i < first.solution.length; i++) {
        expect(first.isPassage(first.solution[i - 1], first.solution[i]), isTrue);
      }

      var passageCount = 0;
      for (var row = 0; row < first.side; row++) {
        for (var column = 0; column < first.side; column++) {
          final cell = MazeCell(row, column);
          if (column + 1 < first.side &&
              first.isPassage(cell, MazeCell(row, column + 1))) passageCount++;
          if (row + 1 < first.side &&
              first.isPassage(cell, MazeCell(row + 1, column))) passageCount++;
        }
      }
      expect(passageCount, first.totalCells - 1);
    });

    test('maze grows with level and remains capped', () {
      expect(ContinuousMazeEngine.forLevel(1).side, 5);
      expect(ContinuousMazeEngine.forLevel(13).side, 6);
      expect(ContinuousMazeEngine.forLevel(100).side,
          ContinuousMazeEngine.maxSide);
    });

    test('only starts at entrance, accepts adjacent corridors and backtracks', () {
      final engine = ContinuousMazeEngine.forLevel(4, seed: 90);
      expect(engine.begin(const MazeCell(1, 1)), MazeMoveResult.invalid);
      expect(engine.path, isEmpty);
      expect(engine.begin(engine.start), MazeMoveResult.started);
      expect(engine.begin(engine.start), MazeMoveResult.ignored);

      final next = engine.solution[1];
      expect(engine.moveTo(next), MazeMoveResult.moved);
      expect(engine.moveTo(engine.start), MazeMoveResult.backtracked);
      expect(engine.path, [engine.start]);

      final closedNeighbor = <MazeCell>[
        MazeCell(0, 1), MazeCell(1, 0),
      ].firstWhere((cell) => !engine.isPassage(engine.start, cell));
      expect(engine.moveTo(closedNeighbor), MazeMoveResult.invalid);
      expect(engine.path, [engine.start]);
      expect(engine.invalidMoves, 2);
    });

    test('tracing the generated route reaches the goal and lifting cancels', () {
      final engine = ContinuousMazeEngine.forLevel(3, seed: 181);
      expect(engine.begin(engine.start), MazeMoveResult.started);
      engine.cancelTrace();
      expect(engine.path, isEmpty);
      expect(engine.invalidMoves, 1);

      expect(engine.begin(engine.start), MazeMoveResult.started);
      for (final cell in engine.solution.skip(1).take(engine.solution.length - 2)) {
        expect(engine.moveTo(cell), MazeMoveResult.moved);
      }
      expect(engine.moveTo(engine.goal), MazeMoveResult.completed);
      expect(engine.complete, isTrue);
      expect(engine.path, engine.solution);
      expect(engine.score, greaterThanOrEqualTo(0));
      expect(engine.moveTo(engine.start), MazeMoveResult.ignored);
    });
  });
}
