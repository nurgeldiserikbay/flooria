import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'arrow_orbit_engine.dart';

class ArrowOrbitPage extends StatefulWidget {
  const ArrowOrbitPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int completedRounds, int mistakes) onSessionEnd;

  @override
  State<ArrowOrbitPage> createState() => _ArrowOrbitPageState();
}

class _ArrowOrbitPageState extends State<ArrowOrbitPage> {
  late OrbitSession session;
  int _revision = 0;
  bool _reported = false;
  OrbitMoveResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _lastResult = null;
    session = OrbitSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 49979687 + _revision++,
    );
  }

  void _select(int index) {
    final result = session.select(index);
    if (result == OrbitMoveResult.invalid) return;
    setState(() => _lastResult = result);
    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.completedRounds, session.mistakes);
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Arrow Orbit', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: _ink,
                    )),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete ? 'All 5 rotations solved'
                          : 'Rotation ${session.roundIndex + 1} of 5',
                      style: const TextStyle(
                        color: _muted, fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE5EBF3),
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _OrbitResults(
                            mistakes: session.mistakes,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _softBlue,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white, width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'TURN ${round.turnLabel.toUpperCase()}',
                                      style: const TextStyle(
                                        color: _blue, letterSpacing: 1,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Which tile lands at ${round.targetLabel}?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _ink, fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${session.mistakes} slips',
                                      style: const TextStyle(
                                        color: _muted, fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, box) {
                                      final side = math.min(
                                        box.maxWidth, box.maxHeight,
                                      );
                                      return SizedBox(
                                        width: side, height: side,
                                        child: GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemCount: round.cellCount,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: OrbitSession.gridSize,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                          itemBuilder: (context, index) {
                                            final isTarget =
                                                index == round.targetIndex;
                                            final isSelected =
                                                index == session.lastSelection;
                                            return _OrbitTile(
                                              key: ValueKey(
                                                'arrow-orbit-cell-$index',
                                              ),
                                              number: index + 1,
                                              target: isTarget,
                                              selected: isSelected,
                                              incorrect: isSelected &&
                                                  _lastResult ==
                                                      OrbitMoveResult.incorrect,
                                              onTap: () => _select(index),
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
                                    _lastResult == OrbitMoveResult.incorrect
                                        ? 'Picture the turn and try another tile.'
                                        : 'The golden marker shows the destination.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _lastResult ==
                                              OrbitMoveResult.incorrect
                                          ? _coral : _muted,
                                      fontSize: 12,
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

class _OrbitTile extends StatelessWidget {
  const _OrbitTile({
    super.key,
    required this.number,
    required this.target,
    required this.selected,
    required this.incorrect,
    required this.onTap,
  });

  final int number;
  final bool target;
  final bool selected;
  final bool incorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = incorrect ? _wrong : selected
        ? _success : target ? _gold : _tile;
    return Semantics(
      button: true,
      label: target ? 'Tile $number, destination' : 'Tile $number',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: target || selected ? Colors.white : _edge, width: 3,
              ),
              boxShadow: target || selected ? const [
                BoxShadow(
                  color: Color(0x22283B57), blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ] : null,
            ),
            child: target
                ? const Icon(Icons.place_rounded, color: _goldInk, size: 25)
                : Text('$number', style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 20, fontWeight: FontWeight.w900,
                  )),
          ),
        ),
      ),
    );
  }
}

class _OrbitResults extends StatelessWidget {
  const _OrbitResults({required this.mistakes, required this.onRetry});
  final int mistakes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.explore_rounded, size: 62, color: _blue),
        const SizedBox(height: 10),
        const Text('Great sense of direction!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900, color: _ink,
          )),
        const SizedBox(height: 8),
        Text('5 rotations solved · $mistakes slips',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('PLAY AGAIN'),
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    ),
  );
}

const _paper = Color(0xFFFAFBFD);
const _ink = Color(0xFF465367);
const _muted = Color(0xFF8B96A7);
const _blue = Color(0xFF7797C6);
const _softBlue = Color(0xFFE7EFF9);
const _tile = Color(0xFFF1F4F8);
const _edge = Color(0xFFE3E9F1);
const _gold = Color(0xFFF4DCA7);
const _goldInk = Color(0xFF9C7627);
const _success = Color(0xFF96CBB0);
const _wrong = Color(0xFFE8AFA7);
const _coral = Color(0xFFC27A70);
