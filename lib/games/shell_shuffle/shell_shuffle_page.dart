import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'shell_shuffle_engine.dart';

enum _ShufflePhase { ready, shuffling, answering, complete }

class ShellShufflePage extends StatefulWidget {
  const ShellShufflePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<ShellShufflePage> createState() => _ShellShufflePageState();
}

class _ShellShufflePageState extends State<ShellShufflePage> {
  late ShellShuffleSession session;
  int _revision = 0;
  int _generation = 0;
  bool _reported = false;
  _ShufflePhase _phase = _ShufflePhase.ready;
  List<int> _cupAtSlot = [];
  int _swapStep = 0;
  int? _wrongSlot;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _generation++;
    _reported = false;
    session = ShellShuffleSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 700001 + _revision++,
    );
    _resetRound();
  }

  void _resetRound() {
    _phase = _ShufflePhase.ready;
    _cupAtSlot = List<int>.generate(session.current.cupCount, (slot) => slot);
    _swapStep = 0;
    _wrongSlot = null;
    _showSuccess = false;
  }

  Future<void> _runShuffle() async {
    if (_phase != _ShufflePhase.ready) return;
    final generation = ++_generation;
    setState(() {
      _phase = _ShufflePhase.shuffling;
      _wrongSlot = null;
      _showSuccess = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!_isCurrent(generation)) return;

    for (final swap in session.current.swaps) {
      if (!_isCurrent(generation)) return;
      setState(() {
        final firstCup = _cupAtSlot[swap.firstSlot];
        _cupAtSlot[swap.firstSlot] = _cupAtSlot[swap.secondSlot];
        _cupAtSlot[swap.secondSlot] = firstCup;
        _swapStep++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!_isCurrent(generation)) return;
    }

    setState(() => _phase = _ShufflePhase.answering);
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  void _chooseCup(int slot) {
    if (_phase != _ShufflePhase.answering) return;
    final result = session.choose(slot);
    if (result == ShellPickResult.invalid) return;

    if (result == ShellPickResult.incorrect) {
      setState(() => _wrongSlot = slot);
      return;
    }

    setState(() {
      _wrongSlot = null;
      if (result == ShellPickResult.complete) {
        _phase = _ShufflePhase.complete;
      } else {
        _resetRound();
        _showSuccess = true;
      }
    });

    if (result == ShellPickResult.complete && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final round = session.current;
    final shuffleReady = _phase == _ShufflePhase.ready;
    final answering = _phase == _ShufflePhase.answering;
    final shuffling = _phase == _ShufflePhase.shuffling;

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
                    child: Text('Shell Shuffle', style: TextStyle(
                      color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
                    )),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'All 5 shuffles tracked'
                          : 'Round ${session.roundIndex + 1} of ${ShellShuffleSession.roundCount} · ${round.swaps.length} swaps',
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
                      backgroundColor: const Color(0xFFECE5F3),
                      color: _violet,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _ShuffleResults(
                            correct: session.correctAnswers,
                            mistakes: session.mistakes,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _softLavender,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white, width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      shuffling
                                          ? 'SWAP $_swapStep / ${round.swaps.length}'
                                          : answering
                                              ? 'STAR HIDDEN'
                                              : 'FOLLOW THE STAR',
                                      style: const TextStyle(
                                        color: _violet, letterSpacing: 1,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      answering
                                          ? 'Where did the star finish?'
                                          : shuffling
                                              ? 'Keep your eyes on the moving cups.'
                                              : _showSuccess
                                                  ? 'Nice tracking! Ready for another?'
                                                  : 'Watch the star, then follow its cup.',
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
                              const SizedBox(height: 12),
                              Expanded(
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, box) {
                                      final count = round.cupCount;
                                      final cupWidth = math.min(
                                        62.0,
                                        (box.maxWidth - (count - 1) * 8) / count,
                                      );
                                      final gap = count == 1
                                          ? 0.0
                                          : (box.maxWidth - cupWidth * count) /
                                              (count - 1);
                                      final totalWidth =
                                          cupWidth * count + gap * (count - 1);
                                      final offset = (box.maxWidth - totalWidth) / 2;
                                      return SizedBox(
                                        width: box.maxWidth,
                                        height: 150,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 17,
                                              child: Container(
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFD9C6A7),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                              ),
                                            ),
                                            for (var cup = 0;
                                                cup < count;
                                                cup++)
                                              _cupToken(
                                                cupId: cup,
                                                slot: _cupAtSlot.indexOf(cup),
                                                left: offset +
                                                    _cupAtSlot.indexOf(cup) *
                                                        (cupWidth + gap),
                                                width: cupWidth,
                                                round: round,
                                                answering: answering,
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (shuffleReady)
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton.icon(
                                    onPressed: _runShuffle,
                                    icon: Icon(_showSuccess
                                        ? Icons.arrow_forward_rounded
                                        : Icons.shuffle_rounded),
                                    label: Text(_showSuccess
                                        ? 'NEXT SHUFFLE'
                                        : 'START SHUFFLE'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _violet,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                )
                              else if (shuffling)
                                const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Text('Watch closely…',
                                      style: TextStyle(
                                        color: _muted,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  ),
                                )
                              else
                                const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Text('Tap the cup hiding the star.',
                                      style: TextStyle(
                                        color: _muted,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _wrongSlot != null
                                        ? 'Not that cup. Follow the labels and try again.'
                                        : 'Cup labels help you keep track of each move.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _wrongSlot != null ? _coral : _muted,
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

  Widget _cupToken({
    required int cupId,
    required int slot,
    required double left,
    required double width,
    required ShellRound round,
    required bool answering,
  }) {
    final revealsStar = _phase == _ShufflePhase.ready &&
        cupId == round.starCup;
    final wrong = slot == _wrongSlot;
    return AnimatedPositioned(
      key: ValueKey('shell-cup-$cupId'),
      duration: const Duration(milliseconds: 390),
      curve: Curves.easeInOutCubic,
      left: left,
      top: 18,
      width: width,
      height: 98,
      child: Semantics(
        button: answering,
        label: revealsStar ? 'Cup ${cupId + 1}, star visible'
            : 'Cup ${cupId + 1}',
        child: InkWell(
          key: ValueKey('shell-shuffle-slot-$slot'),
          onTap: answering ? () => _chooseCup(slot) : null,
          borderRadius: BorderRadius.circular(17),
          child: Column(
            children: [
              Container(
                width: width - 2,
                height: 65,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: wrong ? _wrong : _cup,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: wrong ? _coral : Colors.white, width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x222F2940),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: revealsStar
                    ? const Icon(Icons.star_rounded,
                        size: 31, color: _gold)
                    : Icon(
                        Icons.local_cafe_rounded,
                        size: 29,
                        color: wrong ? Colors.white : _violet,
                      ),
              ),
              const SizedBox(height: 5),
              Text('${cupId + 1}', style: const TextStyle(
                color: _ink, fontSize: 14, fontWeight: FontWeight.w900,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuffleResults extends StatelessWidget {
  const _ShuffleResults({
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
        const Icon(Icons.visibility_rounded, size: 62, color: _violet),
        const SizedBox(height: 10),
        const Text('Sharp eyes!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink, fontSize: 23, fontWeight: FontWeight.w900,
          )),
        const SizedBox(height: 8),
        Text('$correct tracked · $mistakes slips',
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('PLAY AGAIN'),
          style: FilledButton.styleFrom(
            backgroundColor: _violet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    ),
  );
}

const _paper = Color(0xFFFBF9FD);
const _ink = Color(0xFF50485F);
const _muted = Color(0xFF91899D);
const _violet = Color(0xFF9A83BC);
const _softLavender = Color(0xFFF0E9F5);
const _cup = Color(0xFFD8CBE8);
const _gold = Color(0xFFFFD36E);
const _wrong = Color(0xFFE6AAA0);
const _coral = Color(0xFFC17B71);
