import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_shift_engine.dart';

class SceneShiftPage extends StatefulWidget {
  const SceneShiftPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctFinds, int mistakes) onSessionEnd;

  @override
  State<SceneShiftPage> createState() => _SceneShiftPageState();
}

class _SceneShiftPageState extends State<SceneShiftPage> {
  late SceneShiftSession session;
  int _revision = 0;
  int? _wrongTile;
  bool _inputLocked = false;
  bool _reported = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _inputLocked = false;
    _wrongTile = null;
    _reported = false;
    _feedback = null;
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 104729 + _revision;
    _revision++;
    session = SceneShiftSession(seed: seed, level: level);
  }

  void _reveal() {
    if (session.reveal()) {
      setState(() {
        _wrongTile = null;
        _feedback = null;
      });
    }
  }

  void _choose(int index) {
    if (_inputLocked || session.finished) return;
    _inputLocked = true;
    final result = session.choose(index);

    if (result == SceneShiftResult.invalid) {
      _inputLocked = false;
      return;
    }

    setState(() {
      _wrongTile = result == SceneShiftResult.incorrect ? index : null;
      _feedback = switch (result) {
        SceneShiftResult.incorrect => 'That tile stayed the same. Look again.',
        SceneShiftResult.correct => 'Found the change! Remember the next scene.',
        SceneShiftResult.complete => null,
        SceneShiftResult.invalid => null,
      };
    });

    if (result == SceneShiftResult.complete && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctFinds, session.mistakes);
      if (session.passed) widget.onComplete();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _inputLocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final scene = session.current;
    final preview = session.showingPreview;

    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Scene Shift',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${session.mistakes} misses',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'Visual check complete'
                          : 'Scene ${session.roundIndex + 1} of '
                              '${SceneShiftSession.roundCount}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE8EEF1),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: complete
                        ? _SceneResults(
                            correct: session.correctFinds,
                            mistakes: session.mistakes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _softBlue,
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      preview
                                          ? 'STUDY THIS SCENE'
                                          : 'FIND THE CHANGE',
                                      style: const TextStyle(
                                        color: _deepTeal,
                                        letterSpacing: .9,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      preview
                                          ? 'Remember the symbols, then reveal the next scene.'
                                          : 'Tap the one tile that changed.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFEFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: _edge),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      const gap = 6.0;
                                      final rows = scene.rows;
                                      final tileWidth =
                                          (constraints.maxWidth -
                                              gap * (scene.columns - 1)) /
                                          scene.columns;
                                      final tileHeight =
                                          (constraints.maxHeight -
                                              gap * (rows - 1)) /
                                          rows;
                                      final ratio = tileWidth /
                                          math.max(1.0, tileHeight);
                                      final tokens = session.visibleScene;
                                      return GridView.builder(
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: tokens.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: scene.columns,
                                          crossAxisSpacing: gap,
                                          mainAxisSpacing: gap,
                                          childAspectRatio: ratio,
                                        ),
                                        itemBuilder: (context, index) =>
                                            _SceneTile(
                                          key: ValueKey('scene-tile-$index'),
                                          token: tokens[index],
                                          index: index,
                                          selectedWrong: index == _wrongTile,
                                          enabled:
                                              !preview && !_inputLocked,
                                          onTap: () => _choose(index),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              if (preview)
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: FilledButton.icon(
                                    key: const ValueKey('scene-reveal'),
                                    onPressed: _reveal,
                                    icon: const Icon(Icons.visibility_rounded),
                                    label: const Text('SHOW THE CHANGE'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 22,
                                  child: Center(
                                    child: Text(
                                      _feedback ?? 'Choose the changed tile.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _wrongTile == null
                                            ? _muted
                                            : _coral,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({
    super.key,
    required this.token,
    required this.index,
    required this.selectedWrong,
    required this.enabled,
    required this.onTap,
  });

  final SceneToken token;
  final int index;
  final bool selectedWrong;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: enabled,
        label: '${token.color.label} ${token.shape.label}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: selectedWrong ? _wrongFill : _tile,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selectedWrong ? _coral : _tileEdge,
                  width: selectedWrong ? 2.5 : 1.2,
                ),
              ),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) => Icon(
                    token.shape.icon,
                    color: token.color.value,
                    size: math.min(29, constraints.maxHeight * .58),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _SceneResults extends StatelessWidget {
  const _SceneResults({
    required this.correct,
    required this.mistakes,
    required this.passed,
    required this.onRetry,
  });

  final int correct;
  final int mistakes;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.auto_awesome_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _teal : _blue,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Change spotted!' : 'Give it another look',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct scenes found · $mistakes misses',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
}

extension on SceneShape {
  String get label => switch (this) {
        SceneShape.circle => 'circle',
        SceneShape.square => 'square',
        SceneShape.triangle => 'triangle',
        SceneShape.diamond => 'diamond',
        SceneShape.star => 'star',
      };

  IconData get icon => switch (this) {
        SceneShape.circle => Icons.circle_rounded,
        SceneShape.square => Icons.square_rounded,
        SceneShape.triangle => Icons.change_history_rounded,
        SceneShape.diamond => Icons.diamond_rounded,
        SceneShape.star => Icons.star_rounded,
      };
}

extension on SceneColor {
  String get label => switch (this) {
        SceneColor.coral => 'coral',
        SceneColor.blue => 'blue',
        SceneColor.yellow => 'yellow',
        SceneColor.mint => 'mint',
        SceneColor.purple => 'purple',
      };

  Color get value => switch (this) {
        SceneColor.coral => const Color(0xFFE58A7D),
        SceneColor.blue => const Color(0xFF719CCB),
        SceneColor.yellow => const Color(0xFFE2B54C),
        SceneColor.mint => const Color(0xFF67AF93),
        SceneColor.purple => const Color(0xFF9A87C2),
      };
}

const _paper = Color(0xFFFAFBF9);
const _ink = Color(0xFF46504B);
const _muted = Color(0xFF8D9892);
const _teal = Color(0xFF5D9E88);
const _blue = Color(0xFF719CCB);
const _deepTeal = Color(0xFF4D8473);
const _softBlue = Color(0xFFE8F1F4);
const _edge = Color(0xFFE7ECE9);
const _tile = Color(0xFFF8FAF8);
const _tileEdge = Color(0xFFE9EEEA);
const _wrongFill = Color(0xFFFFF0EC);
const _coral = Color(0xFFC87E72);
