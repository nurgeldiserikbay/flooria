import 'dart:math';

import 'package:flutter/material.dart';

import 'pixel_garden_engine.dart';

class PixelGardenPage extends StatefulWidget {
  const PixelGardenPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int mistakes) onSessionEnd;

  @override
  State<PixelGardenPage> createState() => _PixelGardenPageState();
}

class _PixelGardenPageState extends State<PixelGardenPage> {
  late PixelGardenSession session;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + revision * 1543
        : widget.floor! * 1877 + revision;
    session = PixelGardenSession(seed: seed);
    reported = false;
  }

  void _toggle(int cell) {
    if (!session.toggle(cell)) return;
    setState(() {});
  }

  void _advance() {
    if (!session.advance()) return;
    setState(() {});
    if (!session.complete || reported) return;
    reported = true;
    widget.onSessionEnd(PixelGardenSession.totalRounds, session.totalMistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.complete;
    final puzzle = session.puzzle;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EE),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Pixel Garden',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF8FCF5),
        foregroundColor: const Color(0xFF587052),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'LEVEL ${widget.floor}',
                  style: const TextStyle(
                    color: Color(0xFF819278),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_florist_rounded,
                          color: Color(0xFF82B77D), size: 23),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complete
                              ? 'Your garden is in bloom!'
                              : session.roundComplete
                                  ? 'Picture complete!'
                                  : 'Fill the squares from the clues',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF587052),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        complete
                            ? '${PixelGardenSession.totalRounds} / ${PixelGardenSession.totalRounds}'
                            : '${session.round + 1} / ${PixelGardenSession.totalRounds}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF789B70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final cell = min(
                          54.0,
                          min((bounds.maxWidth - 30) / 6,
                              (bounds.maxHeight - 20) / 6.2),
                        ).clamp(24.0, 54.0).toDouble();
                        return Center(
                          child: _NonogramBoard(
                            puzzle: puzzle,
                            disabled: complete || session.roundComplete,
                            cellSize: cell,
                            onTap: _toggle,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complete
                        ? 'Three little pictures, all solved.'
                        : session.roundComplete
                            ? 'Beautiful! Ready for the next picture?'
                            : 'Tap a square to fill it; tap again to clear it.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF819278),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${session.totalMistakes} misplaced squares',
                          style: const TextStyle(
                            color: Color(0xFF819278),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: complete
                            ? () => setState(() {
                                  revision++;
                                  _restart();
                                })
                            : session.roundComplete
                                ? _advance
                                : () => setState(() {
                                      revision++;
                                      _restart();
                                    }),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD991),
                          foregroundColor: const Color(0xFF5E6458),
                        ),
                        icon: Icon(
                          complete || !session.roundComplete
                              ? Icons.refresh_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          complete
                              ? 'PLAY AGAIN'
                              : session.roundComplete
                                  ? 'NEXT PICTURE'
                                  : 'RESTART',
                        ),
                      ),
                    ],
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

class _NonogramBoard extends StatelessWidget {
  const _NonogramBoard({
    required this.puzzle,
    required this.disabled,
    required this.cellSize,
    required this.onTap,
  });

  final PixelGardenPuzzle puzzle;
  final bool disabled;
  final double cellSize;
  final ValueChanged<int> onTap;

  static const _ink = Color(0xFF65835E);
  static const _clue = Color(0xFF7E9277);
  static const _filled = Color(0xFF93C58A);
  static const _tile = Color(0xFFFFFEFA);

  @override
  Widget build(BuildContext context) {
    final labelWidth = cellSize * .55;
    final clueHeight = cellSize * 1.15;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(width: labelWidth, height: clueHeight),
            for (var column = 0; column < PixelGardenPuzzle.size; column++)
              SizedBox(
                width: cellSize,
                height: clueHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: puzzle.columnClues[column]
                      .map((number) => Text(
                            '$number',
                            style: TextStyle(
                              color: _clue,
                              fontSize: cellSize * .19,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
        for (var row = 0; row < PixelGardenPuzzle.size; row++)
          Row(
            children: [
              SizedBox(
                width: labelWidth,
                height: cellSize,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    puzzle.rowClues[row].isEmpty
                        ? '0'
                        : puzzle.rowClues[row].join(' '),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _clue,
                      fontSize: cellSize * .19,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              for (var column = 0;
                  column < PixelGardenPuzzle.size;
                  column++)
                _NonogramCell(
                  key: ValueKey<String>(
                      'pixel-cell-${row * PixelGardenPuzzle.size + column}'),
                  size: cellSize,
                  filled: !disabled &&
                      puzzle.filledCells
                          .contains(row * PixelGardenPuzzle.size + column),
                  revealed: disabled &&
                      puzzle.targetCells
                          .contains(row * PixelGardenPuzzle.size + column),
                  row: row,
                  column: column,
                  enabled: !disabled,
                  onTap: () => onTap(row * PixelGardenPuzzle.size + column),
                ),
            ],
          ),
      ],
    );
  }
}

class _NonogramCell extends StatelessWidget {
  const _NonogramCell({
    super.key,
    required this.size,
    required this.filled,
    required this.revealed,
    required this.row,
    required this.column,
    required this.enabled,
    required this.onTap,
  });

  final double size;
  final bool filled;
  final bool revealed;
  final int row;
  final int column;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = filled || revealed;
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Semantics(
          button: enabled,
          label:
              'Row ${row + 1}, column ${column + 1}, ${active ? 'filled' : 'empty'}',
          child: Material(
            color: active ? const Color(0xFF93C58A) : const Color(0xFFFFFEFA),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: enabled ? onTap : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF7CAD73)
                        : const Color(0xFFD9E6D1),
                  ),
                ),
                child: active
                    ? const Icon(Icons.local_florist_rounded,
                        color: Colors.white, size: 17)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
