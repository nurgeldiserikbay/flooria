import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/ui/neuro_map.dart';

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _showMap(WidgetTester tester, {bool reducedMotion = false}) async {
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Scaffold(
        body: NeuroMapView(
          completedNeurons: const {},
          motionEnabled: true,
          onNodeTap: (_) {},
          onGames: () {},
          onAnalytics: () {},
          onSettings: () {},
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  for (final size in const [
    Size(360, 640),
    Size(390, 844),
    Size(800, 1100),
  ]) {
    testWidgets('map opens on a playable neuron at ${size.width}x${size.height}',
        (tester) async {
      _screen(tester, size);
      await _showMap(tester, reducedMotion: true);
      final start = tester.getCenter(find.byKey(const ValueKey('node_01')));
      expect(start.dx, inInclusiveRange(32, size.width - 32));
      expect(start.dy, inInclusiveRange(122, size.height - 25));
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('late neuron positions do not overlap', (tester) async {
    _screen(tester, const Size(390, 844));
    await _showMap(tester, reducedMotion: true);
    final centers = <int, Offset>{};
    for (var slot = 39; slot <= 55; slot++) {
      final key = ValueKey('node_${slot.toString().padLeft(2, '0')}');
      centers[slot] = tester.getCenter(find.byKey(key));
    }
    for (var i = 39; i <= 55; i++) {
      for (var j = i + 1; j <= 55; j++) {
        expect((centers[i]! - centers[j]!).distance, greaterThan(36),
          reason: 'Nodes $i and $j must have separate tap targets');
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('pattern repeats without stretching the world image',
      (tester) async {
    _screen(tester, const Size(390, 844));
    await _showMap(tester, reducedMotion: true);
    final pattern = find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox ||
          widget.decoration is! BoxDecoration) return false;
      final image = (widget.decoration as BoxDecoration).image;
      return image?.image is AssetImage &&
          (image!.image as AssetImage).assetName ==
              'assets/background/neural_hex_mesh.jpg';
    });
    expect(pattern, findsOneWidget);
    final decoration = tester.widget<DecoratedBox>(pattern)
        .decoration as BoxDecoration;
    expect(decoration.image!.repeat, ImageRepeat.repeat);
    expect(decoration.image!.fit, BoxFit.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion stops idle map animation, pan remains usable',
      (tester) async {
    _screen(tester, const Size(390, 844));
    await _showMap(tester, reducedMotion: true);
    await tester.pumpAndSettle();
    final node = find.byKey(const ValueKey('node_01'));
    final before = tester.getCenter(node);
    await tester.drag(find.byType(InteractiveViewer), const Offset(-55, -95));
    await tester.pumpAndSettle();
    final after = tester.getCenter(node);
    expect((after - before).distance, greaterThan(20));
    expect(tester.takeException(), isNull);
  });
}
