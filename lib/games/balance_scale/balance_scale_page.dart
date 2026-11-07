import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'balance_scale_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF6E7), surface: Colors.white, ink: Color(0xFF66563F),
  muted: Color(0xFF9A8668), accent: Color(0xFFD5A84E), edge: Color(0xFF66563F),
);

Widget buildBalanceScalePage(BuildContext context, GameLaunch launch) =>
    BalanceScalePage(launch: launch);

class BalanceScalePage extends StatefulWidget {
  const BalanceScalePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<BalanceScalePage> createState() => _BalanceScalePageState();
}

class _BalanceScalePageState extends State<BalanceScalePage> with LevelFlow<BalanceScalePage> {
  late BalanceScaleEngine _engine;
  String _message = 'CHOOSE WEIGHTS TO BALANCE THE OBJECT';
  int _wrongPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = BalanceScaleEngine.forLevel(level);
    _message = 'CHOOSE WEIGHTS TO BALANCE THE OBJECT';
    _wrongPulse = 0;
  }

  void _toggle(int index) {
    if (_engine.toggle(index) == BalanceMove.ignored) return;
    setState(() => _message = 'SELECTED TOTAL: ${_engine.total}');
    HapticFeedback.selectionClick();
  }

  void _check() {
    final result = _engine.check();
    if (result == BalanceMove.ignored) return;
    if (result == BalanceMove.balanced) {
      setState(() => _message = 'PERFECT BALANCE');
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      setState(() {
        _message = _engine.total < _engine.target
            ? 'ADD ${_engine.difference} MORE'
            : 'REMOVE ${_engine.difference}';
        _wrongPulse++;
      });
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Balance Scale', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final width = min(constraints.maxWidth - 30, 370.0).toDouble();
      final scaleHeight = min(180.0, constraints.maxHeight * .30).toDouble();
      return Center(child: SizedBox(width: width,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                StatChip(label: 'OBJECT', value: '${_engine.target} KG', palette: _palette),
                StatChip(label: 'YOUR SIDE', value: '${_engine.total} KG', palette: _palette),
              ])),
            const SizedBox(height: 8),
            Semantics(
              label: 'Balance scale: object ${_engine.target} kilograms, '
                  'your weights ${_engine.total} kilograms',
              child: TweenAnimationBuilder<double>(
                key: const ValueKey('balance-scale-motion'),
                tween: Tween<double>(
                  begin: 0,
                  end: _engine.total.toDouble(),
                ),
                duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                    ? Duration.zero : const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, animatedTotal, _) => CustomPaint(
                  size: Size(width, scaleHeight),
                  painter: _ScalePainter(_engine.target, animatedTotal),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 7,
              children: [for (var index = 0; index < _engine.weights.length; index++)
                SizedBox(
                  width: min(64, (width - 32) / 5).toDouble(),
                  height: 48,
                  child: ChunkyButton(
                    onPressed: reported ? null : () => _toggle(index),
                    color: _engine.selected.contains(index)
                        ? const Color(0xFFFFD981) : Colors.white,
                    edgeColor: _palette.edge,
                    depth: 3, radius: 12,
                    padding: EdgeInsets.zero,
                    semanticLabel: '${_engine.weights[index]} kilograms, '
                        '${_engine.selected.contains(index) ? 'selected' : 'not selected'}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_engine.selected.contains(index)) ...[
                          const Icon(Icons.check_rounded,
                            size: 13, color: Color(0xFF66563F)),
                          const SizedBox(width: 1),
                        ],
                        Text('${_engine.weights[index]} kg',
                          style: const TextStyle(
                            color: Color(0xFF66563F),
                            fontSize: 12, fontWeight: FontWeight.w900,
                          )),
                      ],
                    ),
                  ),
                ),
              ]),
            const SizedBox(height: 8),
            if (!reported)
              SizedBox(width: 210, height: 46,
                child: ChunkyButton(onPressed: _engine.selected.isEmpty ? null : _check,
                  color: _palette.accent, edgeColor: _palette.edge, depth: 3, radius: 12,
                  child: const Text('CHECK BALANCE', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, letterSpacing: .8)))),
            if (reported)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: LevelResultPanel(palette: _palette, launch: launch,
                  level: level, stars: _engine.moves <= 4 ? 3 : _engine.moves <= 7 ? 2 : 1,
                  detail: 'Balanced the object with the right weights.',
                  onReplay: replayLevel, onNext: nextLevel))
            else
              Shake(
                trigger: _wrongPulse,
                child: HintLine(_message, palette: _palette),
              ),
          ],
        ),
      ));
    }),
  );
}

class _ScalePainter extends CustomPainter {
  const _ScalePainter(this.target, this.total);
  final int target;
  final double total;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .58);
    final diff = (total - target).clamp(-10, 10).toDouble() / 10;
    final angle = diff * .16;
    final beamLength = size.width * .72;
    final left = center + Offset(-cos(angle) * beamLength / 2, -sin(angle) * beamLength / 2);
    final right = center + Offset(cos(angle) * beamLength / 2, sin(angle) * beamLength / 2);
    final beam = Paint()..color = _palette.edge..strokeWidth = 9..strokeCap = StrokeCap.round;
    canvas.drawLine(left, right, beam);
    final panPaint = Paint()..color = const Color(0xFFB98743)..strokeWidth = 3..style = PaintingStyle.stroke;
    for (final endpoint in [left, right]) {
      final panY = endpoint.dy + 30;
      canvas.drawLine(endpoint, Offset(endpoint.dx - 25, panY), panPaint);
      canvas.drawLine(endpoint, Offset(endpoint.dx + 25, panY), panPaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(endpoint.dx, panY), width: 58, height: 20),
        0, pi, false, panPaint);
    }
    final fulcrum = Path()
      ..moveTo(center.dx, center.dy - 2)
      ..lineTo(center.dx - 37, size.height - 5)
      ..lineTo(center.dx + 37, size.height - 5)
      ..close();
    canvas.drawPath(fulcrum, Paint()..color = const Color(0xFFE0B85C));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(left.dx, left.dy + 25), width: 35, height: 22),
      const Radius.circular(6)), Paint()..color = const Color(0xFF8FBA88));
    final weightText = TextPainter(text: TextSpan(text: '$target',
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr)..layout();
    weightText.paint(canvas, Offset(left.dx - weightText.width / 2,
      left.dy + 25 - weightText.height / 2));
    if (total > 0) {
      final value = TextPainter(text: TextSpan(text: '${total.round()}', style: const TextStyle(
        color: Color(0xFF66563F), fontSize: 12, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)..layout();
      value.paint(canvas, Offset(right.dx - value.width / 2, right.dy + 26));
    }
  }
  @override
  bool shouldRepaint(covariant _ScalePainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.total != total;
}
