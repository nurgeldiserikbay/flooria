import 'package:flutter/material.dart';

import 'belief_detective_engine.dart';

class BeliefDetectivePage extends StatefulWidget {
  const BeliefDetectivePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int mistakes) onSessionEnd;

  @override
  State<BeliefDetectivePage> createState() => _BeliefDetectivePageState();
}

class _BeliefDetectivePageState extends State<BeliefDetectivePage> {
  late BeliefDetectiveSession session;
  int _displayIndex = 0;
  int _revision = 0;
  BeliefPlace? _selectedPlace;
  bool? _lastWasCorrect;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _displayIndex = 0;
    _selectedPlace = null;
    _lastWasCorrect = null;
    _reported = false;
    final floor = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 104729 + _revision;
    _revision++;
    session = BeliefDetectiveSession(seed: seed, level: floor);
  }

  void _answer(BeliefPlace place) {
    if (_selectedPlace != null || session.finished) return;
    final result = session.answer(place);
    if (result == BeliefAnswerResult.invalid) return;

    setState(() {
      _selectedPlace = place;
      _lastWasCorrect = place == session.rounds[_displayIndex].correctPlace;
    });

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctCount, session.mistakes);
      if (widget.floor != null && session.passed) widget.onComplete();
    }
  }

  void _nextStory() {
    if (_selectedPlace == null || session.finished) return;
    setState(() {
      _displayIndex = session.roundIndex;
      _selectedPlace = null;
      _lastWasCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final round = session.rounds[_displayIndex];

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
                          'Belief Detective',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 21,
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
                          ? 'Stories complete'
                          : 'Story ${_displayIndex + 1} of '
                              '${BeliefDetectiveSession.roundCount}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE6EEF0),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: complete
                        ? _BeliefResults(
                            correct: session.correctCount,
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
                                  color: _softMint,
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Text(
                                  'Follow what the character actually saw.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _StoryBoard(round: round),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Where does ${round.character} think the object is now?',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${round.character}’s belief',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (_selectedPlace == null)
                                _BeliefOptions(
                                  round: round,
                                  onChoose: _answer,
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton.icon(
                                    key: const ValueKey('belief-next'),
                                    onPressed: _nextStory,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                    label: const Text('NEXT STORY'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 19,
                                child: Center(
                                  child: Text(
                                    _lastWasCorrect == null
                                        ? 'A character can only know what they noticed.'
                                        : _lastWasCorrect!
                                            ? 'Correct — you tracked their point of view.'
                                            : 'Try again. They may not have seen the move.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _lastWasCorrect == false
                                          ? _coral
                                          : _muted,
                                      fontSize: 10,
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

class _StoryBoard extends StatelessWidget {
  const _StoryBoard({required this.round});

  final BeliefRound round;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _edge),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _softMint,
                  child: Text(
                    round.character[0],
                    style: const TextStyle(
                      color: _deepTeal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${round.character} is tracking a ${round.objectName}.',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'At first, ${round.character} saw it in the '
                '${_placeName(round.initialPlace)}.',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 5),
            for (final move in round.moves)
              _MoveRow(
                character: round.character,
                move: move,
              ),
          ],
        ),
      );
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.character,
    required this.move,
  });

  final String character;
  final BeliefMove move;

  @override
  Widget build(BuildContext context) => Container(
        height: 31,
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: move.characterSaw
              ? const Color(0xFFF1F7F1)
              : const Color(0xFFFFF5EA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              move.characterSaw
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 14,
              color: move.characterSaw ? _teal : _amber,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 39,
              child: Text(
                move.characterSaw ? 'Saw' : 'Away',
                style: TextStyle(
                  color: move.characterSaw ? _deepTeal : _amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${_placeName(move.from)}  →  ${_placeName(move.to)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}

class _BeliefOptions extends StatelessWidget {
  const _BeliefOptions({required this.round, required this.onChoose});

  final BeliefRound round;
  final ValueChanged<BeliefPlace> onChoose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 8) / 2;
          final tileHeight = tileWidth / 2.9;
          final gridHeight = tileHeight * 2 + 8;

          return SizedBox(
            height: gridHeight,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: round.options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.9,
              ),
              itemBuilder: (context, index) {
                final place = round.options[index];
                return Material(
                  color: const Color(0xFFFFFEFC),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: ValueKey('belief-place-${place.index}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChoose(place),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _edge, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _placeIcon(place),
                            size: 17,
                            color: _placeColor(place),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _placeName(place),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _BeliefResults extends StatelessWidget {
  const _BeliefResults({
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
              passed ? Icons.psychology_alt_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _teal : _coral,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Great perspective!' : 'Try tracking the clues again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct correct · $mistakes misses',
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

String _placeName(BeliefPlace place) => switch (place) {
      BeliefPlace.garden => 'Garden',
      BeliefPlace.kitchen => 'Kitchen',
      BeliefPlace.bedroom => 'Bedroom',
      BeliefPlace.playroom => 'Playroom',
    };

IconData _placeIcon(BeliefPlace place) => switch (place) {
      BeliefPlace.garden => Icons.grass_rounded,
      BeliefPlace.kitchen => Icons.restaurant_rounded,
      BeliefPlace.bedroom => Icons.bed_rounded,
      BeliefPlace.playroom => Icons.toys_rounded,
    };

Color _placeColor(BeliefPlace place) => switch (place) {
      BeliefPlace.garden => _green,
      BeliefPlace.kitchen => _amber,
      BeliefPlace.bedroom => const Color(0xFF779ACB),
      BeliefPlace.playroom => _coral,
    };

const _paper = Color(0xFFFAFBF8);
const _ink = Color(0xFF46504B);
const _muted = Color(0xFF8D9892);
const _teal = Color(0xFF5D9E88);
const _deepTeal = Color(0xFF4C8272);
const _softMint = Color(0xFFE5F2EA);
const _edge = Color(0xFFE8EEE9);
const _coral = Color(0xFFC97D72);
const _amber = Color(0xFFB7864F);
const _green = Color(0xFF70AB91);
