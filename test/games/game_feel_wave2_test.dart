import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/lights_out/lights_out_page.dart';
import 'package:flooria/games/pair_match/pair_match_page.dart';
import 'package:flooria/games/water_sort/water_sort_page.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _sizes = [Size(360, 640), Size(390, 844)];

void main() {
  for (final size in _sizes) {
    testWidgets('Pair Match card flip fits ${size.width}x${size.height}',
        (tester) async {
      _setViewport(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: PairMatchPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        )),
      ));
      await tester.tap(find.byKey(const ValueKey('pair-card-0')));
      await tester.pump(const Duration(milliseconds: 360));
      expect(find.byKey(const ValueKey('pair-card-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lights Out toggle fits ${size.width}x${size.height}',
        (tester) async {
      _setViewport(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: LightsOutPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        )),
      ));
      await tester.tap(find.byKey(const ValueKey('lights-cell-0')));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Water Sort tube feedback fits ${size.width}x${size.height}',
        (tester) async {
      _setViewport(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: WaterSortPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        )),
      ));
      await tester.tap(find.byKey(const ValueKey('water-tube-0')));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.byKey(const ValueKey('water-tube-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
