import 'dart:math';

enum BrickTick { moving, lifeLost, cleared, gameOver, idle }

/// Small deterministic paddle-and-ball game; coordinates are board fractions.
class BrickBreakEngine {
  BrickBreakEngine._({required this.level, required this.columns, required this.rows,
    required this.bricks}) : _alive = Set<int>.of(bricks) {
    _serve();
  }

  final int level, columns, rows;
  final Set<int> bricks;
  final Set<int> _alive;
  Set<int> get alive => Set.unmodifiable(_alive);
  double ballX = .5, ballY = .84, paddleX = .5, _vx = .32, _vy = -.68;
  int lives = 3, score = 0;
  bool launched = false, isCompleted = false, isFailed = false;
  int get remaining => _alive.length;
  int get controlMetric => (100 - (3 - lives) * 20).clamp(40, 100).toInt();

  factory BrickBreakEngine.forLevel(int level, {int? seed}) {
    final safe = max(1, level).toInt();
    final columns = safe < 10 ? 6 : 7;
    final rows = min(2 + (safe - 1) ~/ 5, 6).toInt();
    final random = Random(seed ?? safe * 3571 + 29);
    final bricks = <int>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        // Later boards leave a few gaps while remaining fully clearable.
        if (safe < 8 || random.nextDouble() > .12) bricks.add(r * columns + c);
      }
    }
    return BrickBreakEngine._(level: safe, columns: columns, rows: rows, bricks: bricks);
  }

  void setPaddle(double x) => paddleX = x.clamp(.12, .88).toDouble();
  void launchBall() { if (!isCompleted && !isFailed) launched = true; }
  void _serve() {
    launched = false;
    ballX = paddleX;
    ballY = .84;
    _vx = (level.isEven ? -.32 : .32);
    _vy = -.68;
  }

  BrickTick tick(double dt) {
    if (!launched || isCompleted || isFailed) return BrickTick.idle;
    final step = dt.clamp(0.0, .04).toDouble();
    ballX += _vx * step;
    ballY += _vy * step;
    const radius = .018;
    if (ballX < radius) { ballX = radius; _vx = _vx.abs(); }
    if (ballX > 1-radius) { ballX = 1-radius; _vx = -_vx.abs(); }
    if (ballY < .035) { ballY = .035; _vy = _vy.abs(); }

    final brickWidth = .92 / columns;
    final brickHeight = rows > 4 ? .044 : .052;
    for (final index in List<int>.of(_alive)) {
      final row = index ~/ columns, col = index % columns;
      final left = .04 + col * brickWidth, top = .12 + row * (brickHeight + .014);
      if (ballX + radius < left || ballX - radius > left + brickWidth - .012 ||
          ballY + radius < top || ballY - radius > top + brickHeight) {
        continue;
      }
      _alive.remove(index);
      score += 10;
      _vy = -_vy;
      if (_alive.isEmpty) { isCompleted = true; return BrickTick.cleared; }
      return BrickTick.moving;
    }

    const paddleY = .92, halfPaddle = .13;
    if (_vy > 0 && ballY + radius >= paddleY - .025 && ballY <= paddleY + .02 &&
        (ballX - paddleX).abs() <= halfPaddle + radius) {
      final hit = ((ballX - paddleX) / halfPaddle).clamp(-1.0, 1.0).toDouble();
      _vx = hit * .82;
      _vy = -.72 + hit.abs() * .12;
      ballY = paddleY - .03;
      return BrickTick.moving;
    }
    if (ballY > 1.03) {
      lives--;
      if (lives <= 0) { isFailed = true; return BrickTick.gameOver; }
      _serve();
      return BrickTick.lifeLost;
    }
    return BrickTick.moving;
  }
}
