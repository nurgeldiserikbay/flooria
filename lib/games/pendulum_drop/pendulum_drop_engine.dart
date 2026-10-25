import 'dart:math' as math;

/// A deterministic pendulum-timing game in normalized world coordinates.
/// Positive y goes down. Gravity launches the released bob as a projectile.
class PendulumDropSession {
  PendulumDropSession({required this.seed, this.roundCount = 3})
      : assert(roundCount > 0);

  static const double amplitude = 0.76;
  static const double angularSpeed = 2.0;
  static const double ropeLength = 1.0;
  static const double groundY = 1.72;
  static const double gravity = 4.5;
  static const double hitRadius = 0.19;

  final int seed;
  final int roundCount;

  int round = 0;
  int attempts = 0;
  int hits = 0;
  double phase = 0;
  double flightTime = 0;
  double releaseX = 0;
  double releaseY = 0;
  double releaseVX = 0;
  double releaseVY = 0;
  double lastLandingX = 0;
  bool flying = false;
  bool lastShotHit = false;

  bool get finished => round >= roundCount;
  double get angle => amplitude * math.sin(phase);
  double get angleVelocity => amplitude * angularSpeed * math.cos(phase);
  double get bobX => flying ? releaseX + releaseVX * flightTime
      : ropeLength * math.sin(angle);
  double get bobY => flying ? releaseY + releaseVY * flightTime +
      gravity * flightTime * flightTime / 2
      : ropeLength * math.cos(angle);

  /// Target is always taken from a feasible release instant.
  double get targetX {
    final index = ((seed % 7) + round * 3 + 7) % 7;
    const phases = [0.15, 0.48, 0.85, 1.20, 2.05, 2.36, 2.75];
    return landingXForPhase(phases[index]);
  }

  static double landingXForPhase(double atPhase) {
    final theta = amplitude * math.sin(atPhase);
    final omega = amplitude * angularSpeed * math.cos(atPhase);
    final x = ropeLength * math.sin(theta);
    final y = ropeLength * math.cos(theta);
    final vx = ropeLength * omega * math.cos(theta);
    final vy = -ropeLength * omega * math.sin(theta);
    final discriminant = vy * vy + 2 * gravity * (groundY - y);
    final flight = (-vy + math.sqrt(discriminant)) / gravity;
    return x + vx * flight;
  }

  /// Time step is limited to avoid simulation jumps after app suspension.
  /// Returns true if a projectile has just landed.
  bool advance(double dt) {
    if (finished || !dt.isFinite || dt <= 0) return false;
    final delta = dt.clamp(0.0, 0.05);
    if (!flying) {
      phase = (phase + delta * angularSpeed) % (2 * math.pi);
      return false;
    }
    flightTime += delta;
    if (bobY < groundY) return false;
    // Use the analytical landing value, independent of frame rate.
    final a = gravity / 2;
    final b = releaseVY;
    final c = releaseY - groundY;
    final t = (-b + math.sqrt(b * b - 4 * a * c)) / (2 * a);
    lastLandingX = releaseX + releaseVX * t;
    lastShotHit = (lastLandingX - targetX).abs() <= hitRadius;
    flying = false;
    flightTime = 0;
    if (lastShotHit) {
      hits++;
      round++;
      phase = 0;
    }
    return true;
  }

  bool release() {
    if (finished || flying) return false;
    final theta = angle;
    final omega = angleVelocity;
    releaseX = ropeLength * math.sin(theta);
    releaseY = ropeLength * math.cos(theta);
    releaseVX = ropeLength * omega * math.cos(theta);
    releaseVY = -ropeLength * omega * math.sin(theta);
    flightTime = 0;
    attempts++;
    flying = true;
    lastShotHit = false;
    return true;
  }
}
