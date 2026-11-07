import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/combination_lock/combination_lock_engine.dart';
import 'package:flooria/games/number_sequence/number_sequence_engine.dart';
import 'package:flooria/games/whack_target/whack_target_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester,
  String id, {
  int level = 1,
  bool reduceMotion = false,
  ValueChanged<GameResult>? onComplete,
}) async {
  final definition = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Builder(builder: (context) => definition.buildPage(
        context,
        GameLaunch(
          level: level,
          mode: GamePlayMode.standalone,
          maxLevel: 100,
          onComplete: onComplete ?? (_) {},
        ),
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 260));
}

void main() {
  for (final id in const [
    'combination_lock', 'number_sequence', 'whack_target',
  ]) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level fits ${size.width}x${size.height}',
            (tester) async {
          _viewport(tester, size);
          await _open(tester, id, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 210));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Five-digit code slots fit a narrow phone and accept input',
      (tester) async {
    _viewport(tester, const Size(360, 640));
    await _open(tester, 'combination_lock', level: 90);
    final engine = CombinationLockEngine.forLevel(90);
    expect(engine.codeLength, 5);
    for (var slot = 0; slot < engine.codeLength; slot++) {
      final cell = find.byKey(ValueKey('lock-slot-$slot'));
      expect(cell, findsOneWidget);
      final rect = tester.getRect(cell);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    }
    await tester.tap(find.byKey(const ValueKey('lock-slot-1')));
    await tester.pump(const Duration(milliseconds: 190));
    final chosen = tester.widget<Semantics>(
      find.byKey(const ValueKey('lock-slot-1')));
    expect(chosen.properties.selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('lock-key-5')));
    await tester.pump(const Duration(milliseconds: 170));
    expect(find.text('5'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wrong number answer stays visible, next round remains playable',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'number_sequence');
    final engine = NumberSequenceEngine.forLevel(1);
    final wrong = engine.choices.firstWhere((value) => value != engine.answer);
    await tester.tap(find.byKey(ValueKey('sequence-choice-$wrong')));
    await tester.pump(const Duration(milliseconds: 210));
    expect(find.textContaining('NOT QUITE'), findsOneWidget);
    expect(find.byKey(ValueKey('sequence-choice-$wrong')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('sequence-choice-${engine.answer}')));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const ValueKey('sequence-round-1')), findsOneWidget);
    expect(find.textContaining('NOT QUITE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Number Sequence completes once and continues to level 2',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final results = <GameResult>[];
    await _open(tester, 'number_sequence', onComplete: results.add);
    final engine = NumberSequenceEngine.forLevel(1);
    for (var turn = 0; turn < 5; turn++) {
      await tester.tap(find.byKey(ValueKey(
        'sequence-choice-${engine.answer}')));
      engine.choose(engine.answer);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    }
    expect(results, hasLength(1));
    expect(results.single.level, 1);
    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump(const Duration(milliseconds: 210));
    expect(find.text('LEVEL 2'), findsOneWidget);
    expect(results, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Target tap shows a hit and countdown resets next window',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'whack_target');
    final engine = WhackTargetEngine.forLevel(1);
    final target = find.byKey(ValueKey('whack-cell-${engine.target}'));
    expect(tester.widget<Semantics>(target).properties.label,
        contains('Target in spot'));
    expect(find.byKey(const ValueKey('whack-window-0')), findsOneWidget);
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('1/${engine.goal}'), findsOneWidget);
    expect(tester.widget<Semantics>(target).properties.label,
        contains('Target hit'));
    await tester.pump(Duration(
      milliseconds: engine.windowMilliseconds));
    await tester.pump();
    expect(find.byKey(const ValueKey('whack-window-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New microanimations respect reduced motion', (tester) async {
    _viewport(tester, const Size(390, 844));

    await _open(tester, 'combination_lock', reduceMotion: true);
    final slot = find.byKey(const ValueKey('lock-slot-0'));
    final slotScale = tester.widget<AnimatedScale>(
      find.descendant(of: slot, matching: find.byType(AnimatedScale)));
    expect(slotScale.duration, Duration.zero);

    await _open(tester, 'number_sequence', reduceMotion: true);
    final round = tester.widget<AnimatedSwitcher>(
      find.ancestor(
        of: find.byKey(const ValueKey('sequence-round-0')),
        matching: find.byType(AnimatedSwitcher),
      ).first,
    );
    expect(round.duration, Duration.zero);

    await _open(tester, 'whack_target', reduceMotion: true);
    final target = find.byKey(const ValueKey('whack-cell-0'));
    final targetScale = tester.widget<AnimatedScale>(
      find.descendant(of: target, matching: find.byType(AnimatedScale)));
    expect(targetScale.duration, Duration.zero);
    expect(find.byKey(const ValueKey('whack-window-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
