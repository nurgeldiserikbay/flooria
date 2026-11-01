import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'signal_guard_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFF17112D),
  surface: Color(0xFF241B45),
  ink: Color(0xFFF2EEFF),
  muted: Color(0xFF9A8FC4),
  accent: Color(0xFF8C7BFF),
  edge: Color(0xFF07040F),
  success: Color(0xFF4ADE9B),
  danger: Color(0xFFFF6B7A),
);
const _mint = Color(0xFF4ADE9B);
const _coral = Color(0xFFFF6B7A);

Widget buildSignalGuardPage(BuildContext context, GameLaunch launch) =>
    SignalGuardPage(launch: launch);

class SignalGuardPage extends StatefulWidget {
  const SignalGuardPage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<SignalGuardPage> createState() => _SignalGuardPageState();
}

enum _Stage { intro, gap, signal, finished }

class _SignalGuardPageState extends State<SignalGuardPage>
    with LevelFlow<SignalGuardPage> {
  late SignalGuardEngine _engine;
  _Stage _stage = _Stage.intro;
  TrialOutcome? _lastOutcome;
  int _attempt = 0;
  int _generation = 0;
  Timer? _timer;
  final Stopwatch _clock = Stopwatch();

  @override
  GameLaunch get launch => widget.launch;

  @override
  void initState() {
    super.initState();
    resetLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void resetLevel() {
    _timer?.cancel();
    _generation++;
    _engine = SignalGuardEngine.forLevel(level,
      seed: _attempt == 0 ? null : level * 2749 + 5 + _attempt * 7919);
    _stage = _Stage.intro;
    _lastOutcome = null;
  }

  void _retry() {
    _attempt++;
    replayLevel();
  }

  void _after(int ms, VoidCallback action) {
    final generation = _generation;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || generation != _generation) return;
      action();
    });
  }

  void _start() {
    HapticFeedback.selectionClick();
    _queueNext();
  }

  void _queueNext() {
    if (_engine.isFinished) {
      _finish();
      return;
    }
    setState(() => _stage = _Stage.gap);
    _after(_engine.current.delayMs, _showSignal);
  }

  void _showSignal() {
    setState(() {
      _stage = _Stage.signal;
      _lastOutcome = null;
    });
    _clock
      ..reset()
      ..start();
    _after(_engine.windowMs, () {
      _resolve(_engine.timeout());
    });
  }

  void _tapArena() {
    if (_stage != _Stage.signal) return;
    _timer?.cancel();
    _clock.stop();
    _resolve(_engine.respond(_clock.elapsedMilliseconds));
  }

  void _resolve(TrialOutcome? outcome) {
    if (outcome == null) return;
    if (outcome == TrialOutcome.falseAlarm || outcome == TrialOutcome.miss) {
      HapticFeedback.heavyImpact();
    } else if (outcome == TrialOutcome.hit) {
      HapticFeedback.lightImpact();
    }
    setState(() => _lastOutcome = outcome);
    _queueNext();
  }

  void _finish() {
    setState(() => _stage = _Stage.finished);
    if (_engine.passed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score,
        metrics: {'control': _engine.controlMetric});
    }
  }

  @override
  Widget build(BuildContext context) {
    final finished = _stage == _Stage.finished;
    final mean = _engine.meanReactionMs;
    return GameScaffold(
      palette: _palette,
      title: 'Signal Guard',
      level: level,
      titleKey: const ValueKey('signal-title'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(children: [
          _OutcomeStrip(engine: _engine),
          const SizedBox(height: 12),
          _RuleBar(rule: _engine.rule),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              key: const ValueKey('signal-arena'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _tapArena(),
              child: _Arena(
                stage: _stage,
                trial: _engine.current,
                trialIndex: _engine.index,
                windowMs: _engine.windowMs,
                outcome: _lastOutcome,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _stage == _Stage.intro
                ? SizedBox(
                    key: const ValueKey('signal-start'),
                    width: double.infinity,
                    height: 58,
                    child: ChunkyButton(
                      onPressed: _start,
                      color: _palette.accent,
                      padding: EdgeInsets.zero,
                      child: const Text('START', style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900,
                        letterSpacing: 1.4)),
                    ),
                  )
                : finished && _engine.passed
                    ? LevelResultPanel(
                        palette: _palette,
                        launch: launch,
                        level: level,
                        stars: _engine.stars,
                        detail: '${_engine.correctCount}/${_engine.trials.length} right'
                            '${mean == null ? '' : ' · ${mean}ms average'}',
                        onNext: nextLevel,
                        onReplay: () {
                          _attempt++;
                          replayLevel();
                        },
                      )
                    : finished
                        ? RetryPanel(
                            palette: _palette,
                            title: 'SIGNAL LOST',
                            detail: '${_engine.correctCount}/${_engine.trials.length} right · '
                                'need ${(_engine.passRatio * 100).round()}%',
                            onRetry: _retry,
                          )
                        : HintLine('TAP ANYWHERE IN THE ARENA',
                            palette: _palette, height: 58),
          ),
        ]),
      ),
    );
  }
}

class _OutcomeStrip extends StatelessWidget {
  const _OutcomeStrip({required this.engine});
  final SignalGuardEngine engine;

  @override
  Widget build(BuildContext context) => Row(children: [
    for (var i = 0; i < engine.trials.length; i++) ...[
      if (i > 0) const SizedBox(width: 3),
      Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 8,
          decoration: BoxDecoration(
            color: switch (engine.outcomes[i]) {
              TrialOutcome.hit || TrialOutcome.correctRejection => _mint,
              TrialOutcome.miss || TrialOutcome.falseAlarm => _coral,
              null => i == engine.index ? _palette.muted : _palette.surface,
            },
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: _palette.edge, width: 1),
          ),
        ),
      ),
    ],
  ]);
}

class _RuleBar extends StatelessWidget {
  const _RuleBar({required this.rule});
  final SignalRule rule;

  @override
  Widget build(BuildContext context) {
    final (goShape, goTint, stopShape, stopTint) = rule == SignalRule.color
        ? (SignalShape.circle, SignalTint.mint, SignalShape.circle, SignalTint.coral)
        : (SignalShape.circle, null, SignalShape.square, null);
    final goName = rule == SignalRule.color ? 'green signals' : 'circles';
    final stopName = rule == SignalRule.color ? 'red signals' : 'squares';
    Widget side(String label, SignalShape shape, SignalTint? tint) => Expanded(
      child: Semantics(
        label: label == 'TAP' ? 'Tap on $goName' : 'Hold on $stopName',
        excludeSemantics: true,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _palette.edge, width: 2),
          boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          SizedBox(width: 26, height: 26,
            child: CustomPaint(painter: _SignalPainter(shape: shape,
              color: tint == null ? _palette.ink
                  : tint == SignalTint.mint ? _mint : _coral))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: _palette.ink,
              fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          ),
        ]),
      )),
    );
    return Row(children: [
      side('TAP', goShape, goTint),
      const SizedBox(width: 10),
      side('HOLD', stopShape, stopTint),
    ]);
  }
}

class _Arena extends StatelessWidget {
  const _Arena({required this.stage, required this.trial,
    required this.trialIndex, required this.windowMs, required this.outcome});

  final _Stage stage;
  final SignalTrial trial;
  final int trialIndex;
  final int windowMs;
  final TrialOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final good = outcome == TrialOutcome.hit ||
        outcome == TrialOutcome.correctRejection;
    final border = outcome == null ? const Color(0xFF3A2F66)
        : good ? _mint : _coral;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1640),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 3),
        boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 6))],
      ),
      child: LayoutBuilder(builder: (context, box) {
        final side = min(box.maxWidth, box.maxHeight) * .5;
        return Stack(alignment: Alignment.center, children: [
          // Faint concentric rings make the empty arena read as a sensor.
          for (final scale in [1.5, 1.15, .8])
            Container(
              width: side * scale,
              height: side * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .05),
                  width: 1.5),
              ),
            ),
          if (stage == _Stage.signal) ...[
            TweenAnimationBuilder<double>(
              key: ValueKey('ring-$trialIndex'),
              tween: Tween(begin: 1, end: 0),
              duration: Duration(milliseconds: windowMs),
              builder: (context, t, _) => SizedBox(
                width: side * 1.15,
                height: side * 1.15,
                child: CircularProgressIndicator(
                  value: t,
                  strokeWidth: 4,
                  color: Colors.white.withValues(alpha: .5),
                  backgroundColor: Colors.white.withValues(alpha: .06),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey('signal-$trialIndex'),
              tween: Tween(begin: .3, end: 1),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: SizedBox(
                key: const ValueKey('signal-glyph'),
                width: side * .72,
                height: side * .72,
                child: CustomPaint(painter: _SignalPainter(
                  shape: trial.shape,
                  color: trial.tint == SignalTint.mint ? _mint : _coral,
                  glow: true,
                )),
              ),
            ),
          ] else if (stage == _Stage.intro)
            Text('READY?', style: TextStyle(color: _palette.muted,
              fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3))
          else if (stage == _Stage.gap)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .3)),
            ),
        ]);
      }),
    );
  }
}

class _SignalPainter extends CustomPainter {
  const _SignalPainter({required this.shape, required this.color,
    this.glow = false});

  final SignalShape shape;
  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = rect.deflate(size.shortestSide * .08);
    void draw(Paint paint, Rect area) {
      if (shape == SignalShape.circle) {
        canvas.drawOval(area, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(area,
          Radius.circular(area.shortestSide * .14)), paint);
      }
    }
    if (glow) {
      draw(Paint()
        ..color = color.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18), inner);
    }
    draw(Paint()..color = color, inner);
    draw(Paint()
      ..color = const Color(0xFF07040F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2, size.shortestSide * .04), inner);
    draw(Paint()..color = Colors.white.withValues(alpha: .25),
      Rect.fromLTWH(inner.left + inner.width * .2, inner.top + inner.height * .14,
        inner.width * .32, inner.height * .2));
  }

  @override
  bool shouldRepaint(_SignalPainter old) =>
      old.shape != shape || old.color != color || old.glow != glow;
}
