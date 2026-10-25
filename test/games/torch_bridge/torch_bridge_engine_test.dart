import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/torch_bridge/torch_bridge_engine.dart';

void main() {
  test('every stage has a deterministic optimal budget', () {
    for (var seed = -30; seed <= 30; seed++) {
      final session = TorchBridgeSession(seed: seed);
      final again = TorchBridgeSession(seed: seed);
      expect(session.travelerTimes, again.travelerTimes);
      expect(session.timeLimit, again.timeLimit);
      expect(session.timeLimit, greaterThan(0));
      expect(session.travelerTimes, orderedEquals(
        [...session.travelerTimes]..sort()));
    }
  });

  test('classic four person puzzle can be solved in 17 minutes', () {
    final s = TorchBridgeSession(seed: 0);
    expect(s.travelerTimes, [1, 2, 5, 10]);
    expect(s.timeLimit, 17);
    void move(List<int> travelers) {
      for (final id in travelers) expect(s.toggle(id), isTrue);
      expect(s.cross(), isTrue);
      expect(s.outOfTime, isFalse);
    }
    move([0, 1]); // 2
    move([0]);    // 1
    move([2, 3]); // 10
    move([1]);    // 2
    move([0, 1]); // 2
    expect(s.elapsed, 17);
    expect(s.crossings, 5);
    expect(s.solved, isTrue);
    expect(s.nextRound(), isTrue);
    expect(s.round, 1);
    expect(s.elapsed, 0);
  });

  test('invalid selection and crossing cannot change state', () {
    final s = TorchBridgeSession(seed: 2);
    expect(s.toggle(-1), isFalse);
    expect(s.toggle(4), isFalse);
    expect(s.cross(), isFalse);
    expect(s.toggle(0), isTrue);
    expect(s.toggle(1), isTrue);
    expect(s.toggle(2), isFalse); // Only two can hold the torch.
    expect(s.cross(), isTrue);
    expect(s.elapsed, 3);
    expect(s.toggle(2), isFalse); // Torch is on the other bank.
    expect(s.toggle(0), isTrue);
    expect(s.cross(), isTrue);
    expect(s.torchAcross, isFalse);
  });

  test('time overflow is terminal and restart comes from new session', () {
    final s = TorchBridgeSession(seed: 0);
    expect(s.toggle(3), isTrue);
    expect(s.cross(), isTrue); // 10
    expect(s.toggle(3), isTrue);
    expect(s.cross(), isTrue); // 10 more, over 17
    expect(s.outOfTime, isTrue);
    expect(s.mistakes, 1);
    expect(s.toggle(0), isFalse);
    expect(s.cross(), isFalse);
    expect(s.nextRound(), isFalse);
    expect(TorchBridgeSession(seed: 0).elapsed, 0);
  });
}
