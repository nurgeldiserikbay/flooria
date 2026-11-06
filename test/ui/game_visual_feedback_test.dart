import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/ui/game_kit.dart';
import 'package:flooria/ui/neuro_hub_pages.dart';
import 'package:flooria/core/game_registry.dart';

const _palette = GamePalette(
  ground: Color(0xFFF4F6FF),
  surface: Colors.white,
  ink: Color(0xFF273D75),
  muted: Color(0xFF7887A8),
  accent: Color(0xFF776BE0),
  edge: Color(0xFF273D75),
);

void main() {
  testWidgets('tactile button activates once and exposes semantics', (tester) async {
    var presses = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ChunkyButton(
            onPressed: () => presses++,
            color: _palette.accent,
            semanticLabel: 'Play',
            child: const Text('Play'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Play'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(presses, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('button respects reduced-motion preference', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: ChunkyButton(
            onPressed: () {},
            color: _palette.accent,
            child: const Text('Go'),
          ),
        ),
      ),
    ));
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(ChunkyButton),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.duration, Duration.zero);
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('shared game chrome fits ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        home: GameScaffold(
          palette: _palette,
          title: 'Sample Puzzle',
          level: 4,
          child: Center(child: Text('Game board')),
        ),
      ));
      expect(find.text('Sample Puzzle'), findsOneWidget);
      expect(find.text('LEVEL 4'), findsOneWidget);
      expect(find.text('Game board'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('catalog cards open the selected game', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? selectedId;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NeuroGamesPage(
        onTab: (_) {},
        onPlay: (id) => selectedId = id,
        favorites: const <String>{},
        onFavorite: (_) {},
        bestStandaloneLevels: const <String, int>{},
      )),
    ));
    final first = GameRegistry.enabledGames.first;
    expect(find.text(first.title), findsOneWidget);
    await tester.tap(find.text(first.title));
    await tester.pump();
    expect(selectedId, first.id);
    expect(tester.takeException(), isNull);
  });
}
