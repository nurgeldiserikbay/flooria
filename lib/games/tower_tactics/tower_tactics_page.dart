import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tower_tactics_engine.dart';

/// Move every disk to the marked peg without putting a large disk on a small one.
class TowerTacticsPage extends StatefulWidget {
  const TowerTacticsPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves) onSessionEnd;

  @override
  State<TowerTacticsPage> createState() => _TowerTacticsPageState();
}

class _TowerTacticsPageState extends State<TowerTacticsPage> {
  late TowerTacticsSession session;
  int? selectedPeg;
  int revision = 0;
  bool rewarded = false;
  String feedback = 'Move every disk to the glowing peg';

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = TowerTacticsSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 6151 + revision,
    );
    selectedPeg = null;
    rewarded = false;
    feedback = 'Move every disk to the glowing peg';
  }

  void _tapPeg(int peg) {
    if (rewarded) return;
    setState(() {
      if (selectedPeg == null) {
        selectedPeg = peg;
        feedback = session.topDisk(peg) == null
            ? 'That peg is empty — choose a stack'
            : 'Choose where to place the top disk';
        return;
      }
      if (selectedPeg == peg) {
        selectedPeg = null;
        feedback = 'Move every disk to the glowing peg';
        return;
      }
      final from = selectedPeg!;
      selectedPeg = null;
      if (!session.move(from, peg)) {
        feedback = 'A smaller disk must stay on top';
        return;
      }
      feedback = session.complete
          ? 'Tower complete!'
          : session.roundsCompleted > 0
              ? 'Great move — next tower'
              : 'Nice! Keep building the tower';
    });
    if (session.complete && !rewarded) {
      rewarded = true;
      widget.onSessionEnd(session.roundsCompleted, session.moves);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF33466F);
    const mint = Color(0xFF4DAF9A);
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7F5),
      appBar: AppBar(
        title: const Text('Tower Tactics',
            style: TextStyle(fontWeight: FontWeight.w900)),
        toolbarHeight: 48,
        foregroundColor: ink,
        backgroundColor: const Color(0xFFF8FCFB),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF71839B))),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final short = constraints.maxHeight < 510;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, short ? 5 : 10, 14, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDDF3EB), Color(0xFFE9EDFF), Color(0xFFFFF0E5)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.stacked_bar_chart_rounded,
                        color: mint, size: 21),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text('TOWER ${session.round} / ${session.roundCount}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7)),
                    ),
                    const SizedBox(width: 8),
                    _StatPill(label: 'MOVES', value: '${session.roundMoves}'),
                  ],
                ),
                SizedBox(height: short ? 3 : 8),
                Text(feedback,
                    key: const ValueKey('tower-tactics-feedback'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: feedback.contains('smaller')
                            ? const Color(0xFFB66955)
                            : const Color(0xFF71809B),
                        fontSize: short ? 12 : 13,
                        fontWeight: FontWeight.w800)),
                Expanded(
                  child: LayoutBuilder(builder: (context, boardConstraints) {
                    final diskHeight = math.min(
                      26.0,
                      (boardConstraints.maxHeight * .31 / session.diskCount)
                          .clamp(15.0, 26.0),
                    ).toDouble();
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var peg = 0; peg < TowerTacticsSession.pegCount; peg++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: _PegView(
                                  peg: peg,
                                  disks: session.board[peg],
                                  diskCount: session.diskCount,
                                  isTarget: peg == session.targetPeg,
                                  isSelected: peg == selectedPeg,
                                  diskHeight: diskHeight,
                                  onTap: () => _tapPeg(peg),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                SizedBox(height: short ? 3 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: Color(0xFF8291A8), size: 17),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Tap a stack, then a peg',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: const Color(0xFF71809B),
                            fontWeight: FontWeight.w800,
                            fontSize: short ? 11 : 12))),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        revision++;
                        _restart();
                      }),
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Restart'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF66789B),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xBFFFFFFF),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label  ',
              style: const TextStyle(
                  color: Color(0xFF8A98AC),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF405273),
                  fontWeight: FontWeight.w900,
                  fontSize: 12)),
        ]),
      );
}

class _PegView extends StatelessWidget {
  const _PegView({
    required this.peg,
    required this.disks,
    required this.diskCount,
    required this.isTarget,
    required this.isSelected,
    required this.diskHeight,
    required this.onTap,
  });

  final int peg;
  final List<int> disks;
  final int diskCount;
  final bool isTarget;
  final bool isSelected;
  final double diskHeight;
  final VoidCallback onTap;

  static const colors = [
    Color(0xFFF0A987),
    Color(0xFF7FB9D5),
    Color(0xFF9C92D4),
    Color(0xFFE6C46E),
    Color(0xFF78B99C),
    Color(0xFFDB88A4),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = const Color(0xFF405273);
    return Semantics(
      button: true,
      label: isTarget ? 'Target peg ${peg + 1}' : 'Peg ${peg + 1}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.only(top: 14, bottom: 8),
          padding: const EdgeInsets.fromLTRB(5, 9, 5, 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFDDF6EE)
                : const Color(0xA6FFFFFF),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF57B99B)
                    : isTarget
                        ? const Color(0xFF9DCDBD)
                        : const Color(0xCCFFFFFF),
                width: isSelected || isTarget ? 2 : 1),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x183D5470),
                  blurRadius: 12,
                  offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (isTarget)
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFF59AA91), size: 15),
                Text(isTarget ? 'GOAL' : String.fromCharCode(65 + peg),
                    style: TextStyle(
                        color: isTarget ? const Color(0xFF4E9B83) : ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: .7)),
              ]),
              const SizedBox(height: 6),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 5,
                        height: math
                            .min(190.0, diskCount * diskHeight + 14)
                            .toDouble(),
                        decoration: BoxDecoration(
                            color: const Color(0xFFBCC9CF),
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    Positioned(
                      left: 1,
                      right: 1,
                      bottom: 0,
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9BABB2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final size in disks.reversed)
                          Container(
                            width: 36.0 + (size - 1) * 9.0,
                            height: diskHeight - 2,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: colors[(size - 1) % colors.length],
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: const Color(0xD1FFFFFF),
                                  width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x18334A63),
                                    blurRadius: 3,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text('${disks.length} ${disks.length == 1 ? 'disk' : 'disks'}',
                  style: const TextStyle(
                      color: Color(0xFF8A98AC),
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
