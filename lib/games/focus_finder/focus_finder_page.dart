import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'focus_finder_engine.dart';

class FocusFinderPage extends StatefulWidget {
  const FocusFinderPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctFinds, int mistakes) onSessionEnd;

  @override
  State<FocusFinderPage> createState() => _FocusFinderPageState();
}

class _FocusFinderPageState extends State<FocusFinderPage> {
  late FocusFinderSession session;
  int _revision = 0;
  int? _wrongCell;
  String? _feedback;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _wrongCell = null;
    _feedback = null;
    _reported = false;
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 104729 + _revision;
    _revision++;
    session = FocusFinderSession(seed: seed, level: level);
  }

  void _choose(int index) {
    final result = session.choose(index);
    if (result == SearchPickResult.invalid) return;

    if (result == SearchPickResult.incorrect) {
      setState(() {
        _wrongCell = index;
        _feedback = 'Look for the shape and color together.';
      });
      return;
    }

    setState(() {
      _wrongCell = null;
      _feedback = result == SearchPickResult.complete
          ? null
          : 'Found it! Scan the next group.';
    });

    if (result == SearchPickResult.complete && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctFinds, session.mistakes);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final round = session.current;

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
                          'Focus Finder',
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
                          ? 'Search complete'
                          : 'Round ${session.round + 1} of ${FocusFinderSession.roundCount}',
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
                      backgroundColor: const Color(0xFFECEAE3),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: complete
                        ? _FocusResults(
                            correct: session.correctFinds,
                            mistakes: session.mistakes,
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
                                  color: _softMint,
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _TargetBadge(token: round.target),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'FIND THE MATCH',
                                            style: TextStyle(
                                              color: _deepTeal,
                                              letterSpacing: .9,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Find the ${round.target.color.label} '
                                            '${round.target.shape.label}',
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const gap = 7.0;
                                    final rows = round.rows;
                                    final tileWidth =
                                        (constraints.maxWidth -
                                            gap * (round.columns - 1)) /
                                        round.columns;
                                    final tileHeight =
                                        (constraints.maxHeight -
                                            gap * (rows - 1)) /
                                        rows;
                                    final ratio = tileWidth /
                                        math.max(1.0, tileHeight);
                                    return GridView.builder(
                                      padding: EdgeInsets.zero,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: round.tokens.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: round.columns,
                                        crossAxisSpacing: gap,
                                        mainAxisSpacing: gap,
                                        childAspectRatio: ratio,
                                      ),
                                      itemBuilder: (context, index) =>
                                          _SearchCell(
                                        key: ValueKey('focus-cell-$index'),
                                        token: round.tokens[index],
                                        selectedWrong: index == _wrongCell,
                                        index: index,
                                        onTap: () => _choose(index),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _feedback ?? 'Compare both features.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _wrongCell == null
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

class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.token});

  final SearchToken token;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          token.shape.icon,
          color: token.color.value,
          size: 30,
        ),
      );
}

class _SearchCell extends StatelessWidget {
  const _SearchCell({
    super.key,
    required this.token,
    required this.selectedWrong,
    required this.index,
    required this.onTap,
  });

  final SearchToken token;
  final bool selectedWrong;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${token.color.label} ${token.shape.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: selectedWrong ? _wrongFill : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selectedWrong ? _coral : _edge,
                width: selectedWrong ? 2.5 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x102A3835),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) => Icon(
                  token.shape.icon,
                  color: token.color.value,
                  size: math.min(30, constraints.maxHeight * .62),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusResults extends StatelessWidget {
  const _FocusResults({
    required this.correct,
    required this.mistakes,
    required this.onRetry,
  });

  final int correct;
  final int mistakes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.center_focus_strong_rounded,
                size: 62, color: _teal),
            const SizedBox(height: 10),
            const Text(
              'Sharp eyes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct targets found · $mistakes misses',
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

extension on SearchShape {
  String get label => switch (this) {
        SearchShape.circle => 'circle',
        SearchShape.square => 'square',
        SearchShape.triangle => 'triangle',
        SearchShape.diamond => 'diamond',
      };

  IconData get icon => switch (this) {
        SearchShape.circle => Icons.circle_rounded,
        SearchShape.square => Icons.square_rounded,
        SearchShape.triangle => Icons.change_history_rounded,
        SearchShape.diamond => Icons.diamond_rounded,
      };
}

extension on SearchColor {
  String get label => switch (this) {
        SearchColor.coral => 'coral',
        SearchColor.blue => 'blue',
        SearchColor.yellow => 'yellow',
        SearchColor.green => 'green',
        SearchColor.purple => 'purple',
      };

  Color get value => switch (this) {
        SearchColor.coral => const Color(0xFFE58C7C),
        SearchColor.blue => const Color(0xFF6D9FD0),
        SearchColor.yellow => const Color(0xFFE4B94F),
        SearchColor.green => const Color(0xFF67AF91),
        SearchColor.purple => const Color(0xFF9B88C7),
      };
}

const _paper = Color(0xFFFAFBF8);
const _ink = Color(0xFF434C46);
const _muted = Color(0xFF8C978F);
const _teal = Color(0xFF65A995);
const _deepTeal = Color(0xFF4D8978);
const _softMint = Color(0xFFE5F3EC);
const _edge = Color(0xFFE9EEE9);
const _wrongFill = Color(0xFFFFF0EC);
const _coral = Color(0xFFC97E70);
