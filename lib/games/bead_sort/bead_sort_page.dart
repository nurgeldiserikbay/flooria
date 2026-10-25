import 'dart:math';

import 'package:flutter/material.dart';

import 'bead_sort_engine.dart';

class BeadSortPage extends StatefulWidget {
  const BeadSortPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves) onSessionEnd;

  @override
  State<BeadSortPage> createState() => _BeadSortPageState();
}

class _BeadSortPageState extends State<BeadSortPage> {
  late BeadSortSession session;
  int revision = 0;
  int? selectedTube;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    final floor = widget.floor ?? 1;
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + revision * 1543
        : floor * 1877 + revision;
    session = BeadSortSession(seed: seed, floor: floor);
    selectedTube = null;
    reported = false;
  }

  void _tapTube(int index) {
    if (session.complete || session.roundComplete) return;
    if (selectedTube == null) {
      if (session.puzzle.tubes[index].isNotEmpty) {
        setState(() => selectedTube = index);
      }
      return;
    }

    final from = selectedTube!;
    if (from == index) {
      setState(() => selectedTube = null);
      return;
    }
    if (!session.move(from, index)) {
      if (session.puzzle.tubes[index].isNotEmpty) {
        setState(() => selectedTube = index);
      } else {
        setState(() => selectedTube = null);
      }
      return;
    }

    setState(() => selectedTube = null);
    if (session.complete || !session.roundComplete || reported) return;
    if (session.round == BeadSortSession.totalRounds - 1) {
      session.advance();
      reported = true;
      widget.onSessionEnd(BeadSortSession.totalRounds, session.totalMoves);
      if (widget.floor != null) widget.onComplete();
      setState(() {});
    }
  }

  void _nextRound() {
    if (!session.advance()) return;
    setState(() {});
    if (session.complete && !reported) {
      reported = true;
      widget.onSessionEnd(BeadSortSession.totalRounds, session.totalMoves);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = session.puzzle;
    final complete = session.complete;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F4),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Bead Sort', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF7FCF9),
        foregroundColor: const Color(0xFF46695D),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        color: Color(0xFF78978C),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
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
                      const Icon(Icons.science_rounded,
                          color: Color(0xFF71AA91), size: 23),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complete
                              ? 'All colors sorted!'
                              : session.roundComplete
                                  ? 'Lovely sorting!'
                                  : 'Sort each color into its own tube',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF46695D),
                              fontWeight: FontWeight.w900,
                              fontSize: 14),
                        ),
                      ),
                      Text(
                        complete
                            ? '${BeadSortSession.totalRounds} / ${BeadSortSession.totalRounds}'
                            : '${session.round + 1} / ${BeadSortSession.totalRounds}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF719887)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final width = bounds.maxWidth;
                        final tubeWidth = min(78.0, (width - 24) / 3.2);
                        final tubeHeight = min(178.0, bounds.maxHeight * .39);
                        return Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 18,
                            children: List<Widget>.generate(
                              BeadSortPuzzle.tubeCount,
                              (index) => _Tube(
                                key: ValueKey<String>('bead-tube-$index'),
                                index: index,
                                beads: complete ? const [] : puzzle.tubes[index],
                                selected: selectedTube == index,
                                enabled: !complete && !session.roundComplete,
                                width: tubeWidth,
                                height: tubeHeight,
                                onTap: () => _tapTube(index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${session.totalMoves} pours · tap a tube, then its destination',
                          maxLines: 2,
                          style: const TextStyle(
                              color: Color(0xFF78978C),
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: complete
                            ? () => setState(() {
                                  revision++;
                                  _restart();
                                })
                            : session.roundComplete
                                ? _nextRound
                                : () => setState(() {
                                      revision++;
                                      _restart();
                                    }),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD893),
                          foregroundColor: const Color(0xFF5E645E),
                        ),
                        icon: Icon(complete || !session.roundComplete
                            ? Icons.refresh_rounded
                            : Icons.arrow_forward_rounded),
                        label: Text(complete
                            ? 'PLAY AGAIN'
                            : session.roundComplete
                                ? 'NEXT ROUND'
                                : 'RESTART'),
                      ),
                    ],
                  ),
                  if (complete)
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Text('Every bead found its place.',
                          style: TextStyle(
                              color: Color(0xFF527C70),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
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

class _Tube extends StatelessWidget {
  const _Tube({
    super.key,
    required this.index,
    required this.beads,
    required this.selected,
    required this.enabled,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final int index;
  final List<BeadColor> beads;
  final bool selected;
  final bool enabled;
  final double width;
  final double height;
  final VoidCallback onTap;

  static const colors = <Color>[
    Color(0xFFEF9B89),
    Color(0xFF83C4A5),
    Color(0xFF81B9DA),
    Color(0xFFAA98D4),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      label: 'Tube ${index + 1}, ${beads.length} beads${selected ? ', selected' : ''}',
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: selected ? const Color(0xFFE5F3EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: width - 8,
                    decoration: BoxDecoration(
                      color: const Color(0x99FFFFFF),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF71AA91)
                            : const Color(0xFFBED6C9),
                        width: selected ? 2.5 : 1.5,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(22),
                        top: Radius.circular(11),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List<Widget>.generate(
                        BeadSortPuzzle.capacity,
                        (slot) {
                          final beadIndex = slot -
                              (BeadSortPuzzle.capacity - beads.length);
                          final occupied =
                              beadIndex >= 0 && beadIndex < beads.length;
                          final color = occupied
                              ? colors[beads[beadIndex].index]
                              : Colors.transparent;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(20),
                                  border: occupied
                                      ? Border.all(
                                          color: Colors.white.withValues(alpha: .8),
                                          width: 1.5)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                      color: Color(0xFF8AA89C),
                      fontSize: 11,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
