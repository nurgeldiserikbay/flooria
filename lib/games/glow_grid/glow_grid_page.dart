import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glow_grid_engine.dart';

class GlowGridPage extends StatefulWidget {
  const GlowGridPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int completedBoards, int moves) onSessionEnd;

  @override
  State<GlowGridPage> createState() => _GlowGridPageState();
}

class _GlowGridPageState extends State<GlowGridPage> {
  late GlowGridSession session;
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
    session = GlowGridSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 32452843 + _revision++,
      level: widget.floor ?? 1,
    );
  }

  void _toggle(int index) {
    final result = session.toggle(index);
    if (result == GlowGridMoveResult.invalid) return;
    setState(() {
      _feedback = session.finished
          ? 'Every light is off. Lovely work!'
          : result == GlowGridMoveResult.boardSolved
              ? 'Grid cleared! Keep going.'
              : null;
    });
    if (session.finished) _reportCompletion();
  }

  void _reportCompletion() {
    if (_reported || !session.finished) return;
    _reported = true;
    widget.onSessionEnd(session.completedBoards, session.moves);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final board = session.current;
    final lit = session.litCells;

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Glow Grid',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _paper,
        foregroundColor: _ink,
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () => setState(_startSession),
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _muted)),
              ),
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
                      const Icon(Icons.light_mode_rounded,
                          color: _gold, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Tap a light to toggle its neighbours.',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _ink,
                                fontSize: 14)),
                      ),
                      Text(
                        complete
                            ? '${session.completedBoards} / ${GlowGridSession.boardCount}'
                            : '${session.boardIndex + 1} / ${GlowGridSession.boardCount}',
                        style: const TextStyle(
                            color: _lavender, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE8E3F5),
                      color: _lavender,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _ResultsPanel(
                            moves: session.moves,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: _softLavender,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('LIGHTS LEFT',
                                        style: TextStyle(
                                            color: _muted,
                                            letterSpacing: 1.2,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900)),
                                    Text('${lit.length}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            height: 1.1,
                                            color: _ink,
                                            fontWeight: FontWeight.w900)),
                                    Text('${session.moves} taps',
                                        style: const TextStyle(
                                            color: _muted,
                                            fontWeight: FontWeight.w700)),
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
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: board.size,
                                            crossAxisSpacing: 7,
                                            mainAxisSpacing: 7,
                                          ),
                                          itemBuilder: (context, index) {
                                            final isLit =
                                                lit.contains(index);
                                            return _GlowTile(
                                              key: ValueKey(
                                                  'glow-grid-cell-$index'),
                                              index: index,
                                              lit: isLit,
                                              onTap: () => _toggle(index),
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
                                        'Turn every light off to clear the grid.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: _muted,
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
}

class _GlowTile extends StatelessWidget {
  const _GlowTile({
    super.key,
    required this.index,
    required this.lit,
    required this.onTap,
  });

  final int index;
  final bool lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cell ${index + 1}, ${lit ? "lit" : "off"}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lit ? _warmYellow : _tile,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: lit ? Colors.white : const Color(0xFFE6E1D7),
                  width: 3),
              boxShadow: lit
                  ? const [
                      BoxShadow(
                          color: Color(0x33D3A64F),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ]
                  : null,
            ),
            child: Icon(
              lit ? Icons.lightbulb_rounded : Icons.circle_outlined,
              size: lit ? 28 : 20,
              color: lit ? _amber : _quiet,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.moves, required this.onRetry});

  final int moves;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_rounded, size: 62, color: _amber),
            const SizedBox(height: 10),
            const Text('All aglow!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _ink)),
            const SizedBox(height: 8),
            Text(
              '${GlowGridSession.boardCount} grids cleared in $moves taps.',
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
                backgroundColor: _lavender,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
}

const _paper = Color(0xFFF8F8FC);
const _ink = Color(0xFF46536B);
const _muted = Color(0xFF8792A3);
const _lavender = Color(0xFF9987C6);
const _softLavender = Color(0xFFEAE5F6);
const _tile = Color(0xFFF0EEF5);
const _quiet = Color(0xFFC9C3D6);
const _warmYellow = Color(0xFFFFE7A8);
const _amber = Color(0xFFD39E43);
const _gold = Color(0xFFE3B657);
