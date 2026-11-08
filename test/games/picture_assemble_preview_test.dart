import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openPicture(WidgetTester tester, int level) async {
  final game = GameRegistry.byId('picture_assemble');
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => game.buildPage(context, GameLaunch(
      level: level, mode: GamePlayMode.standalone,
      onComplete: (_) {},
    ))),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Picture Assembly level $level on $size',
          (tester) async {
        viewport(tester, size);
        await openPicture(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('picture-preview-open')),
          findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Reference picture opens and closes without resetting puzzle',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openPicture(tester, 1);
    final before = tester.widgetList<Semantics>(
      find.byType(Semantics)).length;
    expect(before, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('picture-preview-open')));
    await tester.pumpAndSettle();
    expect(find.text('Finished picture'), findsOneWidget);
    expect(find.byKey(const ValueKey('picture-large-preview')),
      findsOneWidget);
    await tester.tap(find.text('BACK TO PUZZLE'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('picture-large-preview')), findsNothing);
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
