import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'precision_stop_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF2FF), surface: Colors.white, ink: Color(0xFF2E4268),
  muted: Color(0xFF7B8DAA), accent: Color(0xFF657BE0), edge: Color(0xFF2E4268),
);

Widget buildPrecisionStopPage(BuildContext context, GameLaunch launch) =>
    PrecisionStopPage(launch: launch);

class PrecisionStopPage extends StatefulWidget {
  const PrecisionStopPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<PrecisionStopPage> createState() => _PrecisionStopPageState();
}

class _PrecisionStopPageState extends State<PrecisionStopPage>
    with LevelFlow<PrecisionStopPage> {
  late PrecisionStopEngine _engine;
  final Stopwatch _watch = Stopwatch();
  Timer? _refresh;
  bool _running = false;
  String _message = 'STOP NEAR THE TARGET TIME';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _refresh?.cancel(); _watch.stop(); super.dispose(); }
  @override
  void resetLevel() {
    _refresh?.cancel();
    _watch.reset();
    _running = false;
    _message = 'STOP NEAR THE TARGET TIME';
    _engine = PrecisionStopEngine(level);
  }

  void _start() {
    if (_running || reported) return;
    _watch.reset();
    _watch.start();
    setState(() { _running = true; _message = 'TAP STOP WHEN IT MATCHES'; });
    _refresh = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (mounted && _running) setState(() {});
    });
  }

  void _stop() {
    if (!_running) return;
    _watch.stop();
    _refresh?.cancel();
    final result = _engine.stopAt(_watch.elapsedMicroseconds / 1000000);
    setState(() {
      _running = false;
      _message = switch (result) {
        StopResult.hit => 'NICE — NEXT TARGET',
        StopResult.early => 'TOO EARLY — TRY AGAIN',
        StopResult.late => 'TOO LATE — TRY AGAIN',
        StopResult.completed => 'THREE CLEAN STOPS',
        StopResult.ignored => _message,
      };
    });
    if (result == StopResult.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score,
        metrics: {'control': _engine.precisionMetric});
    } else if (result == StopResult.hit) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  String _clock(double seconds) => seconds.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Precision Stop',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth - 40,
          constraints.maxHeight - (reported ? 230 : 180)).clamp(220.0, 390.0).toDouble();
      final shown = _running ? _watch.elapsedMicroseconds / 1000000 : 0.0;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            StatChip(label: 'HITS', value: '${_engine.round}/3', palette: _palette),
            const SizedBox(width: 10),
            StatChip(label: 'MISSES', value: '${_engine.misses}', palette: _palette),
          ]),
          const SizedBox(height: 18),
          SizedBox(width: size, height: size,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: _running
                    ? (shown / _engine.targetSeconds).clamp(0.0, 1.0).toDouble()
                    : 0,
                strokeWidth: 13,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0xFFDCE5F5),
                color: _running && shown > _engine.targetSeconds
                    ? const Color(0xFFE98A75) : _palette.accent,
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_running ? _clock(shown) : '0.00',
                  style: const TextStyle(color: _palette.ink,
                    fontSize: 48, fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 8),
                Text('TARGET  ${_clock(_engine.targetSeconds)} s',
                  style: const TextStyle(color: _palette.muted,
                    fontSize: 12, fontWeight: FontWeight.w900,
                    letterSpacing: 1.1)),
              ]),
            ])),
          const SizedBox(height: 18),
          Text(_message, style: TextStyle(color: _palette.muted,
            fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
          const SizedBox(height: 12),
          if (!reported)
            SizedBox(width: 190, height: 54,
              child: ChunkyButton(onPressed: _running ? _stop : _start,
                color: _running ? const Color(0xFFE87978) : _palette.accent,
                child: Text(_running ? 'STOP' : 'START',
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)))),
          if (reported) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.precisionMetric >= 90 ? 3
                    : _engine.precisionMetric >= 70 ? 2 : 1,
                detail: 'Average timing error: ${(_engine.totalError / 3).toStringAsFixed(2)} s.',
                onReplay: replayLevel, onNext: nextLevel)),
          ],
        ]));
    }),
  );
}
