import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import 'pattern_repeat_engine.dart';

const _ink = Color(0xFF273D75);
const _muted = Color(0xFF7887A8);
const _accent = Color(0xFF776BE0);
const _paper = Color(0xFFF4F6FF);

const _padColors = <Color>[
  Color(0xFF5C9FE8),
  Color(0xFF51B7A3),
  Color(0xFFF0AF59),
  Color(0xFFE98293),
  Color(0xFF8A78DF),
  Color(0xFF56B7D4),
  Color(0xFF9DBD56),
  Color(0xFFEB8A59),
  Color(0xFF6E83D5),
];

Widget buildPatternRepeatPage(BuildContext context, GameLaunch launch) =>
    PatternRepeatPage(launch: launch);

class PatternRepeatPage extends StatefulWidget {
  const PatternRepeatPage({super.key, required this.launch});

  final GameLaunch launch;

  @override
  State<PatternRepeatPage> createState() => _PatternRepeatPageState();
}

class _PatternRepeatPageState extends State<PatternRepeatPage> {
  late final PatternRepeatEngine _engine;
  int? _activeCell;
  bool _showingPattern = true;
  bool _complete = false;
  bool _wrongTap = false;
  bool _reported = false;
  Timer? _delayTimer;
  Completer<void>? _delayCompleter;

  @override
  void initState() {
    super.initState();
    _engine = PatternRepeatEngine.forLevel(widget.launch.level);
    unawaited(_showPattern());
  }

  Future<void> _showPattern() async {
    if (!mounted) return;
    setState(() {
      _showingPattern = true;
      _activeCell = null;
      _wrongTap = false;
    });
    await _wait(const Duration(milliseconds: 380));

    for (final cell in _engine.sequence) {
      if (!mounted) return;
      setState(() => _activeCell = cell);
      await _wait(const Duration(milliseconds: 360));
      if (!mounted) return;
      setState(() => _activeCell = null);
      await _wait(const Duration(milliseconds: 130));
    }

    if (mounted) setState(() => _showingPattern = false);
  }

  Future<void> _tapCell(int cell) async {
    if (_showingPattern || _complete) return;
    final result = _engine.tap(cell);
    if (result == PatternTapResult.ignored) return;

    if (result == PatternTapResult.incorrect) {
      HapticFeedback.selectionClick();
      setState(() {
        _wrongTap = true;
        _activeCell = cell;
      });
      await _wait(const Duration(milliseconds: 300));
      await _showPattern();
      return;
    }

    if (result == PatternTapResult.completed) {
      HapticFeedback.lightImpact();
      setState(() {
        _complete = true;
        _activeCell = cell;
      });
      if (!_reported) {
        _reported = true;
        widget.launch.onComplete(GameResult(
          score: _engine.score,
          metrics: {'memory': max(0, 100 - _engine.mistakes * 10)},
        ));
      }
      return;
    }

    setState(() => _activeCell = cell);
    await _wait(const Duration(milliseconds: 110));
    if (mounted) setState(() => _activeCell = null);
  }

  Future<void> _wait(Duration duration) {
    final completer = Completer<void>();
    _delayCompleter = completer;
    _delayTimer = Timer(duration, () {
      _delayTimer = null;
      _delayCompleter = null;
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    if (!(_delayCompleter?.isCompleted ?? true)) {
      _delayCompleter!.complete();
    }
    _delayTimer = null;
    _delayCompleter = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _engine.inputIndex / _engine.sequence.length;
    final subtitle = _complete
        ? 'Pattern complete'
        : _showingPattern
            ? 'Watch the pattern'
            : _wrongTap
                ? 'Watch once more'
                : 'Your turn';

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 4,
        title: Text('Pattern  ·  ${widget.launch.level}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: _LevelPill(level: widget.launch.level)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final boardSide = (constraints.maxWidth - 44)
              .clamp(240.0, 420.0).toDouble();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(subtitle.toUpperCase(),
                      key: const ValueKey('pattern-status'),
                      style: TextStyle(
                        color: _complete ? const Color(0xFF43A987) : _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.7,
                      )),
                    const SizedBox(height: 10),
                    Text(
                      _complete
                          ? 'You remembered all ${_engine.sequence.length} steps.'
                          : _showingPattern
                              ? 'Remember each light.'
                              : 'Repeat it in the same order.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _complete ? 1 : progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E7F5),
                            color: _complete
                                ? const Color(0xFF43A987) : _accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${_engine.inputIndex}/${_engine.sequence.length}',
                        style: const TextStyle(
                          color: _muted, fontWeight: FontWeight.w800)),
                    ]),
                    const Spacer(),
                    SizedBox(
                      width: boardSide,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: PatternRepeatEngine.boardSize,
                          itemBuilder: (context, index) => _PatternPad(
                            key: ValueKey('pattern-pad-$index'),
                            color: _padColors[index],
                            active: _activeCell == index,
                            enabled: !_showingPattern && !_complete,
                            wrong: _wrongTap && _activeCell == index,
                            onTap: () => _tapCell(index),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_complete)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('CONTINUE',
                            style: TextStyle(fontWeight: FontWeight.w900,
                              letterSpacing: 1.1)),
                        ),
                      )
                    else
                      Text(
                        _showingPattern
                            ? 'STEP ${(_activeCell == null ? 0 : _engine.sequence.indexOf(_activeCell!) + 1)} OF ${_engine.sequence.length}'
                            : 'MISTAKES ${_engine.mistakes}',
                        style: const TextStyle(
                          color: _muted, fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('LV $level', style: const TextStyle(
      color: _accent, fontSize: 11, fontWeight: FontWeight.w900)),
  );
}

class _PatternPad extends StatelessWidget {
  const _PatternPad({super.key, required this.color, required this.active,
    required this.enabled, required this.wrong, required this.onTap});

  final Color color;
  final bool active;
  final bool enabled;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: active ? 1.035 : 1,
    duration: const Duration(milliseconds: 100),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('pattern-pad-button'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: .48),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: wrong ? const Color(0xFFE35C66)
                  : active ? Colors.white : color.withValues(alpha: .2),
              width: wrong || active ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: active ? .35 : .11),
                blurRadius: active ? 18 : 7,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              width: active ? 20 : 13,
              height: active ? 20 : 13,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: active ? .95 : .7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
