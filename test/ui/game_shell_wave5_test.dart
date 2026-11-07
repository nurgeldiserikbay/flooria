import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';
import 'package:flooria/ui/neuro_hub_pages.dart';

const _light = GamePalette(
  ground: Color(0xFFF4F6FF),
  surface: Colors.white,
  ink: Color(0xFF29354F),
  muted: Color(0xFF71809B),
  accent: Color(0xFF8176D7),
  edge: Color(0xFF29354F),
);

const _dark = GamePalette(
  ground: Color(0xFF0F1530),
  surface: Color(0xFF1A2347),
  ink: Color(0xFFEAF0FF),
  muted: Color(0xFF8C98C4),
  accent: Color(0xFF4FD8BC),
  edge: Color(0xFF060A1C),
  onAccent: Color(0xFF07251F),
);

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _library(ValueChanged<String> onPlay, {double textScale = 1}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: NeuroGamesPage(
          onTab: (_) {},
          onPlay: onPlay,
          favorites: const <String>{},
          onFavorite: (_) {},
          bestStandaloneLevels: const <String, int>{},
        ),
      ),
    ),
  );
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('compact game search works on ${size.width}x${size.height}',
        (tester) async {
      _phone(tester, size);
      String? chosen;
      await tester.pumpWidget(_library((id) => chosen = id));

      expect(GameRegistry.enabledGames.length, greaterThanOrEqualTo(50));
      expect(find.byKey(const ValueKey('game-search-field')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('toggle-game-search')));
      await tester.pump();
      final search = find.byKey(const ValueKey('game-search-field'));
      expect(search, findsOneWidget);

      await tester.enterText(search, 'mIRRoR');
      await tester.pump();
      expect(find.text('Mirror Beam'), findsOneWidget);
      expect(find.text('Pattern Repeat'), findsNothing);
      await tester.tap(find.text('Mirror Beam'));
      expect(chosen, 'mirror_beam');

      await tester.enterText(search, 'no-such-game-xyz');
      await tester.pump();
      expect(find.text('No games found'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('toggle-game-search')));
      await tester.pump();
      expect(find.byKey(const ValueKey('game-search-field')), findsNothing);
      expect(find.text('Pattern Repeat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('library cards remain readable at 1.5x text scale',
      (tester) async {
    _phone(tester, const Size(360, 640));
    await tester.pumpWidget(_library((_) {}, textScale: 1.5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Pattern Repeat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark games use a dark ambient game-surface gradient',
      (tester) async {
    _phone(tester, const Size(360, 640));
    await tester.pumpWidget(const MaterialApp(
      home: GameScaffold(
        palette: _dark,
        title: 'Synapse Link',
        level: 5,
        child: Center(child: Text('Puzzle')),
      ),
    ));
    final gradients = tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    ).where((w) {
      if (w.decoration is! BoxDecoration) {
        return false;
      }
      final gradient = (w.decoration as BoxDecoration).gradient;
      return gradient is LinearGradient && gradient.colors.length == 3;
    }).toList();
    expect(gradients, isNotEmpty);
    final color = ((gradients.first.decoration as BoxDecoration)
        .gradient! as LinearGradient).colors[1];
    expect(ThemeData.estimateBrightnessForColor(color), Brightness.dark);
    expect(find.text('LEVEL 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('win result honours reduced motion, retains action flow',
      (tester) async {
    _phone(tester, const Size(360, 640));
    var next = 0;
    var replay = 0;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(child: Padding(
            padding: const EdgeInsets.all(16),
            child: LevelResultPanel(
              palette: _light,
              launch: GameLaunch(
                level: 2, maxLevel: 100,
                mode: GamePlayMode.standalone,
                onComplete: (_) {},
              ),
              level: 2,
              stars: 3,
              detail: 'Well done!',
              onNext: () => next++,
              onReplay: () => replay++,
            ),
          )),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL CLEAR'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-confetti')), findsNothing);
    await tester.tap(find.text('NEXT LEVEL'));
    await tester.pump();
    expect(next, 1);
    final replayButton = find.byWidgetPredicate(
      (widget) => widget is ChunkyButton &&
          widget.semanticLabel == 'Replay',
    );
    await tester.tap(replayButton);
    await tester.pump();
    expect(replay, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal motion retains brief celebration animation',
      (tester) async {
    _phone(tester, const Size(390, 844));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LevelResultPanel(
          palette: _light,
          launch: GameLaunch(
            level: 1, mode: GamePlayMode.standalone,
            onComplete: (_) {},
          ),
          level: 1,
          stars: 2,
          detail: 'Great!',
          onNext: () {},
          onReplay: () {},
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('level-confetti')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('segment progress respects reduced motion', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: SegmentBar(total: 4, done: 2, palette: _light),
          ),
        ),
      ),
    ));
    final bars = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(bars.length, 4);
    for (final bar in bars) {
      expect(bar.duration, Duration.zero);
    }
  });
}
