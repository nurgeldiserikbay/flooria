import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pendulum_drop/pendulum_drop_engine.dart';

void main() {
  test('each target is physically reachable from a deterministic release', () {
    for (var seed = -9; seed < 90; seed++) {
      final game = PendulumDropSession(seed: seed);
      final again = PendulumDropSession(seed: seed);
      expect(game.targetX, again.targetX);
      for (var round = 0; round < game.roundCount; round++) {
        final target = game.targetX;
        // The pendulum can be dropped at some phase to hit the target.
        var solution = false;
        for (var step = 0; step < 400; step++) {
          final phase = step * 6.283185307179586 / 400;
          if ((PendulumDropSession.landingXForPhase(phase) - target).abs() <
              PendulumDropSession.hitRadius) {
            solution = true;
            break;
          }
        }
        expect(solution, true, reason: 'seed $seed, stage $round');
        // Advance to the target phase and land successfully.
        for (var i = 0; i < 400 && !game.finished && !game.flying; i++) {
          if ((PendulumDropSession.landingXForPhase(game.phase) - target).abs()
              <= PendulumDropSession.hitRadius * .45) {
            game.release();
            break;
          }
          game.advance(.01);
        }
        expect(game.flying, true, reason: 'phase was reachable');
        var landed = false;
        for (var i = 0; i < 400 && !landed; i++) {
          landed = game.advance(.02);
        }
        expect(landed, true);
        expect(game.lastShotHit, true, reason: 'seed $seed, stage $round');
        expect(game.hits, round + 1);
      }
      expect(game.finished, true);
      expect(game.attempts, 3);
    }
  });

  test('rejects duplicate release, finished play and invalid elapsed times', () {
    final game = PendulumDropSession(seed: 4);
    expect(game.advance(-1), false);
    expect(game.advance(double.nan), false);
    expect(game.release(), true);
    expect(game.release(), false);
    expect(game.attempts, 1);
    expect(game.advance(0), false);
  });

  test('landing is frame-step independent within simulation tolerance', () {
    final one = PendulumDropSession(seed: 2);
    final two = PendulumDropSession(seed: 2);
    for (var i = 0; i < 22; i++) {
      one.advance(.025);
      two.advance(.025);
    }
    one.release();
    two.release();
    var landedOne = false;
    var landedTwo = false;
    for (var i = 0; i < 200 && !landedOne; i++) {
      landedOne = one.advance(.01);
    }
    for (var i = 0; i < 200 && !landedTwo; i++) {
      landedTwo = two.advance(.02);
    }
    expect(landedOne, true);
    expect(landedTwo, true);
    expect(one.lastLandingX, closeTo(two.lastLandingX, .00001));
  });
}
