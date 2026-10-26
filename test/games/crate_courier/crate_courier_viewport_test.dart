import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/crate_courier/crate_courier_engine.dart';
import 'package:flooria/games/crate_courier/crate_courier_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Crate Courier fits $size with board and controls visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: CrateCourierPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __, ___) {},
        ),
      ));

      expect(find.text('Crate Courier'), findsOneWidget);
      expect(find.text('Warehouse 1 of 3'), findsOneWidget);
      for (final key in <String>[
        'courier-cell-1-1',
        'courier-cell-5-5',
        'courier-move-up',
        'courier-move-left',
        'courier-move-right',
        'courier-move-down',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.top, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(size.width), reason: key);
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: key);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('solving all rounds reports results and completion once',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var solvedRounds = -1;
    var reportedMoves = -1;
    var reportedPushes = -1;
    final expected = CrateCourierSession(seed: 15485863, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: CrateCourierPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (rounds, moves, pushes) {
          solvedRounds = rounds;
          reportedMoves = moves;
          reportedPushes = pushes;
        },
      ),
    ));

    for (var round = 0; round < CrateCourierSession.roundCount; round++) {
      final path = _findSolution(expected.currentBoard)!;
      for (final direction in path) {
        await tester.tap(
          find.byKey(ValueKey('courier-move-${direction.name}')),
        );
        await tester.pump();
        expected.currentBoard.move(direction);
      }
      expect(find.byKey(const ValueKey('courier-next')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('courier-next')));
      await tester.pump();
      expected.advanceRound();
    }

    expect(find.text('All crates delivered!'), findsOneWidget);
    expect(completions, 1);
    expect(solvedRounds, CrateCourierSession.roundCount);
    expect(reportedMoves, expected.totalMoves);
    expect(reportedPushes, expected.totalPushes);
    expect(tester.takeException(), isNull);
  });
}

class _SearchState {
  const _SearchState(this.player, this.crates);
  final BoardPoint player;
  final List<BoardPoint> crates;
}

class _SearchNode {
  const _SearchNode(this.state, this.parent, this.direction);
  final _SearchState state;
  final String? parent;
  final CourierDirection? direction;
}

List<CourierDirection>? _findSolution(CrateBoard board) {
  final start = _SearchState(board.playerStart, board.crates);
  final startKey = _stateKey(start);
  final nodes = <String, _SearchNode>{
    startKey: _SearchNode(start, null, null),
  };
  final queue = <String>[startKey];
  var cursor = 0;
  String? goalKey;

  while (cursor < queue.length) {
    final key = queue[cursor++];
    final state = nodes[key]!.state;
    if (state.crates.every(board.targets.contains)) {
      goalKey = key;
      break;
    }

    for (final direction in CourierDirection.values) {
      final next = state.player + direction.offset;
      if (_isWall(next, board)) continue;
      final crates = List<BoardPoint>.of(state.crates);
      final crateIndex = crates.indexOf(next);
      if (crateIndex >= 0) {
        final beyond = next + direction.offset;
        if (_isWall(beyond, board) || crates.contains(beyond)) continue;
        crates[crateIndex] = beyond;
      }
      final candidate = _SearchState(next, crates);
      final candidateKey = _stateKey(candidate);
      if (nodes.containsKey(candidateKey)) continue;
      nodes[candidateKey] = _SearchNode(candidate, key, direction);
      queue.add(candidateKey);
    }
  }

  if (goalKey == null) return null;
  final path = <CourierDirection>[];
  var current = goalKey;
  while (nodes[current]!.parent != null) {
    final node = nodes[current]!;
    path.add(node.direction!);
    current = node.parent!;
  }
  return path.reversed.toList();
}

String _stateKey(_SearchState state) {
  final boxes = state.crates.map((point) => '${point.row},${point.col}').toList()
    ..sort();
  return '${state.player.row},${state.player.col}|${boxes.join(';')}';
}

bool _isWall(BoardPoint point, CrateBoard board) =>
    point.row <= 0 ||
    point.col <= 0 ||
    point.row >= board.size - 1 ||
    point.col >= board.size - 1 ||
    board.walls.contains(point);
