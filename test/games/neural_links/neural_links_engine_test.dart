import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/neural_links/neural_links_engine.dart';

void main() {
  group('NeuralLinksSession', () {
    test('seeded layouts are deterministic and start with crossings', () {
      final first = NeuralLinksSession(seed: 739);
      final second = NeuralLinksSession(seed: 739);
      expect(first.crossingCount, greaterThan(0));
      expect(first.positions.map((point) => (point.x, point.y)).toList(),
          second.positions.map((point) => (point.x, point.y)).toList());
      expect(first.links.length, 8);
      expect(first.crossingLinkIndices, isNotEmpty);
    });

    test('a generated layout can be untangled and solved once', () {
      final session = NeuralLinksSession(seed: 2025);
      final target = List<NeuralPoint>.generate(session.nodeCount, (index) {
        final angle = -pi / 2 + 2 * pi * index / session.nodeCount;
        return NeuralPoint(0.5 + 0.37 * cos(angle), 0.5 + 0.37 * sin(angle));
      });
      for (var index = 0; index < target.length && !session.finished; index++) {
        final current = session.positions[index];
        if ((current.x - target[index].x).abs() >= 0.001 ||
            (current.y - target[index].y).abs() >= 0.001) {
          expect(session.moveNode(index, target[index].x, target[index].y), isTrue);
        }
      }
      expect(session.finished, isTrue);
      expect(session.crossingCount, 0);
      expect(session.moveNode(0, 0.5, 0.5), isFalse);
    });

    test('rejects invalid and non-finite movement', () {
      final session = NeuralLinksSession(seed: 100);
      final before = session.positions;
      expect(session.moveNode(-1, 0.4, 0.4), isFalse);
      expect(session.moveNode(session.nodeCount, 0.4, 0.4), isFalse);
      expect(session.moveNode(0, double.nan, 0.4), isFalse);
      expect(session.positions, same(before));
      expect(session.moves, 0);
    });

    test('clamps coordinates to the playable board', () {
      final session = NeuralLinksSession(seed: 541);
      session.moveNode(0, 2, -1);
      expect(session.positions[0].x, 0.96);
      expect(session.positions[0].y, 0.04);
    });
  });
}
