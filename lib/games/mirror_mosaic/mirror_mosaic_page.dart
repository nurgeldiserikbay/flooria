import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mirror_mosaic_engine.dart';

class MirrorMosaicPage extends StatefulWidget {
  const MirrorMosaicPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int completedBoards, int mistakes) onSessionEnd;

  @override
  State<MirrorMosaicPage> createState() => _MirrorMosaicPageState();
}

class _MirrorMosaicPageState extends State<MirrorMosaicPage> {
  late MirrorMosaicSession session;
  int _revision = 0;
  bool _reported = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _feedback = null;
    session = MirrorMosaicSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 32452843 + _revision++,
    );
  }

  void _toggle(int index) {
    final result = session.toggle(index);
    if (result == MirrorMosaicMoveResult.invalid) return;

    setState(() {
      _feedback = result == MirrorMosaicMoveResult.boardSolved
          ? session.finished
              ? 'Every pattern is complete!'
              : 'Nice reflection. Match the next shape.'
          : session.mistakes > 0
              ? 'A tile was outside the reflected pattern.'
              : null;
    });
    if (session.finished) _reportCompletion();
  }

  void _reportCompletion() {
    if (_reported || !session.finished) return;
    _reported = true;
    widget.onSessionEnd(session.completedBoards, session.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final board = session.current;
    final selected = session.selected;

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Mirror Mosaic',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        backgroundColor: _paper,
        foregroundColor: _ink,
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () => setState(_startSession),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: _violet, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Copy the pattern across the axis.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _ink,
                                fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        complete
                            ? '${session.completedBoards} / ${MirrorMosaicSession.boardCount}'
                            : '${session.boardIndex + 1} / ${MirrorMosaicSession.boardCount}',
                        style: const TextStyle(
                            color: _violet, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFEAE1F2),
                      color: _violet,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _ResultsPanel(
                            mistakes: session.mistakes,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: _softPink,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'MATCH ${board.targetCount} CELLS',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: _muted,
                                            letterSpacing: 1,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${selected.length}/${board.targetCount} · ${session.mistakes} slips',
                                      maxLines: 1,
                                      style: const TextStyle(
                                          color: _ink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final side = math.min(
                                        constraints.maxWidth,
                                        constraints.maxHeight,
                                      );
                                      return SizedBox(
                                        width: side,
                                        height: side,
                                        child: GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemCount: board.cellCount,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                MirrorMosaicSession.gridSize,
                                            crossAxisSpacing: 6,
                                            mainAxisSpacing: 6,
                                          ),
                                          itemBuilder: (context, index) {
                                            final isSource =
                                                board.sourceCells.contains(index);
                                            final isPlayable =
                                                board.isPlayable(index);
                                            final isAxis =
                                                _isAxisCell(board, index);
                                            final isSelected =
                                                selected.contains(index);
                                            final isCorrect = board.targetCells
                                                .contains(index);
                                            return _MirrorTile(
                                              key: ValueKey(
                                                  'mirror-mosaic-cell-$index'),
                                              index: index,
                                              source: isSource,
                                              playable: isPlayable,
                                              axis: isAxis,
                                              selected: isSelected,
                                              selectionCorrect: isCorrect,
                                              axisIcon: board.axis ==
                                                      MirrorAxis.vertical
                                                  ? Icons.swap_horiz_rounded
                                                  : Icons.swap_vert_rounded,
                                              axisCenter:
                                                  index == board.axisIndex *
                                                      board.size +
                                                      board.axisIndex,
                                              onTap: isPlayable
                                                  ? () => _toggle(index)
                                                  : null,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _feedback ??
                                        'The glowing tiles show the original pattern.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: _feedback != null &&
                                                session.mistakes > 0
                                            ? _coral
                                            : _muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
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

  bool _isAxisCell(MirrorMosaicBoard board, int index) {
    final row = index ~/ board.size;
    final column = index % board.size;
    return board.axis == MirrorAxis.vertical
        ? column == board.axisIndex
        : row == board.axisIndex;
  }
}

class _MirrorTile extends StatelessWidget {
  const _MirrorTile({
    super.key,
    required this.index,
    required this.source,
    required this.playable,
    required this.axis,
    required this.selected,
    required this.selectionCorrect,
    required this.axisIcon,
    required this.axisCenter,
    required this.onTap,
  });

  final int index;
  final bool source;
  final bool playable;
  final bool axis;
  final bool selected;
  final bool selectionCorrect;
  final IconData axisIcon;
  final bool axisCenter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = source
        ? _source
        : selected
            ? selectionCorrect
                ? _success
                : _wrong
            : playable
                ? _playTile
                : _tile;
    final icon = source
        ? Icons.star_rounded
        : axis && axisCenter
            ? axisIcon
            : selected
                ? selectionCorrect
                    ? Icons.check_rounded
                    : Icons.close_rounded
                : null;

    return Semantics(
      button: playable,
      label: axis
          ? 'Symmetry axis'
          : source
              ? 'Pattern tile'
              : playable
                  ? 'Reflected tile ${index + 1}${selected ? ", selected" : ""}'
                  : 'Empty tile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: source || selected ? Colors.white : _tileEdge,
                width: 3,
              ),
              boxShadow: source || selected
                  ? const [
                      BoxShadow(
                          color: Color(0x222A2542),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ]
                  : null,
            ),
            child: icon == null
                ? null
                : Icon(
                    icon,
                    size: source ? 26 : 18,
                    color: source
                        ? _violet
                        : selected
                            ? Colors.white
                            : _axisInk,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.mistakes, required this.onRetry});

  final int mistakes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 62, color: _violet),
            const SizedBox(height: 10),
            const Text('Perfectly balanced!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: _ink)),
            const SizedBox(height: 8),
            Text(
              '${MirrorMosaicSession.boardCount} patterns matched · $mistakes slips',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
}

const _paper = Color(0xFFFAF8FC);
const _ink = Color(0xFF4D465D);
const _muted = Color(0xFF8D879B);
const _violet = Color(0xFF9B82BC);
const _softPink = Color(0xFFF1E5F1);
const _source = Color(0xFFE5D9F2);
const _playTile = Color(0xFFFFF8EC);
const _tile = Color(0xFFF2EEF4);
const _tileEdge = Color(0xFFE8E2EA);
const _success = Color(0xFF98C9B0);
const _wrong = Color(0xFFE9AFA5);
const _coral = Color(0xFFC98276);
const _axisInk = Color(0xFFB8AFC0);
