import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/core/neuron_progression.dart';
import 'package:flooria/ui/game_kit.dart';

class _FlowHarness extends StatefulWidget {
  const _FlowHarness({required this.launch});
  final GameLaunch launch;

  @override
  State<_FlowHarness> createState() => _FlowHarnessState();
}

class _FlowHarnessState extends State<_FlowHarness>
    with LevelFlow<_FlowHarness> {
  int resets = 0;

  @override
  GameLaunch get launch => widget.launch;

  @override
  void initState() {
    super.initState();
    resetLevel();
  }

  @override
  void resetLevel() {
    resets++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('LEVEL $level'),
        Text('Reset $resets'),
        Text('Reported $reported'),
        TextButton(
          key: const ValueKey('win'),
          onPressed: () => setState(() => reportWin(
            score: 500,
            metrics: const {'logic': 90},
          )),
          child: const Text('Win'),
        ),
        TextButton(
          key: const ValueKey('next'),
          onPressed: nextLevel,
          child: const Text('Next'),
        ),
        TextButton(
          key: const ValueKey('replay'),
          onPressed: replayLevel,
          child: const Text('Replay'),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Standalone stays in the game until the final level',
      (tester) async {
    final results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: _FlowHarness(launch: GameLaunch(
        level: 98,
        maxLevel: 100,
        mode: GamePlayMode.standalone,
        onComplete: results.add,
      )),
    ));
    expect(find.text('LEVEL 98'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('win')));
    await tester.tap(find.byKey(const ValueKey('win')));
    expect(results, hasLength(1), reason: 'One win per cleared attempt');
    expect(results.single.level, 98);
    expect(results.single.completesNeuron, isFalse);

    await tester.tap(find.byKey(const ValueKey('next')));
    await tester.pump();
    expect(find.text('LEVEL 99'), findsOneWidget);
    expect(find.text('Reset 2'), findsOneWidget);
    expect(find.text('Reported false'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('win')));
    expect(results.map((result) => result.level), [98, 99]);

    await tester.tap(find.byKey(const ValueKey('next')));
    await tester.pump();
    expect(find.text('LEVEL 100'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('win')));
    expect(results.map((result) => result.level), [98, 99, 100]);
    expect(results.last.completesNeuron, isFalse);
  });

  testWidgets('Replay rebuilds the same level and permits a new attempt',
      (tester) async {
    final results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: _FlowHarness(launch: GameLaunch(
        level: 7,
        mode: GamePlayMode.standalone,
        onComplete: results.add,
      )),
    ));
    await tester.tap(find.byKey(const ValueKey('win')));
    await tester.pump();
    expect(find.text('Reported true'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('replay')));
    await tester.pump();
    expect(find.text('LEVEL 7'), findsOneWidget);
    expect(find.text('Reset 2'), findsOneWidget);
    expect(find.text('Reported false'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('win')));
    expect(results, hasLength(2),
      reason: 'Replay is a new attempt; persistence deduplicates levels');
  });

  testWidgets('Map node is completed only on its final assigned level',
      (tester) async {
    final results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: _FlowHarness(launch: GameLaunch(
        level: 10,
        maxLevel: 12,
        mode: GamePlayMode.neuron,
        onComplete: results.add,
      )),
    ));
    for (final expectedLevel in [10, 11, 12]) {
      expect(find.text('LEVEL $expectedLevel'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('win')));
      expect(results.last.level, expectedLevel);
      expect(results.last.completesNeuron, expectedLevel == 12);
      if (expectedLevel != 12) {
        await tester.tap(find.byKey(const ValueKey('next')));
        await tester.pump();
      }
    }
    expect(results, hasLength(3));
  });

  testWidgets('Next on the final level returns to the previous route',
      (tester) async {
    final results = <GameResult>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          key: const ValueKey('open'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => _FlowHarness(
              launch: GameLaunch(
                level: 100,
                maxLevel: 100,
                mode: GamePlayMode.standalone,
                onComplete: results.add,
              ),
            )),
          ),
          child: const Text('Open game'),
        ),
      )),
    ));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 100'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('win')));
    await tester.tap(find.byKey(const ValueKey('next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open')), findsOneWidget);
    expect(find.text('LEVEL 100'), findsNothing);
    expect(results.single.level, 100);
  });

  test('Progress persists 100 consecutive standalone levels', () {
    final progress = PlayerProgress();
    const id = 'pattern_repeat';
    for (var level = 1; level <= 100; level++) {
      expect(progress.nextStandaloneLevel(id), level);
      progress.completeStandaloneLevel(id, level, 100 + level);
    }
    expect(progress.nextStandaloneLevel(id), 100);
    expect(progress.bestStandaloneLevels[id], 100);
    final restored = PlayerProgress.fromJson(progress.toJson());
    expect(restored.bestStandaloneLevels[id], 100);
    expect(restored.nextStandaloneLevel(id), 100);
  });

  test('Map records intermediate levels without prematurely unlocking', () {
    final progress = PlayerProgress();
    const node = 'node_01';
    expect(progress.availability(node), NeuronAvailability.open);
    progress.recordNeuronLevel(node, 1);
    progress.recordNeuronLevel(node, 2);
    expect(progress.nextNeuronLevel(node, 1, 3), 3);
    expect(progress.availability(node), NeuronAvailability.open);
    progress.recordNeuronLevel(node, 3);
    progress.completeNeuron(node);
    expect(progress.availability(node), NeuronAvailability.complete);
    expect(progress.availability('node_02'), NeuronAvailability.open);
  });
}
