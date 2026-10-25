import 'package:flutter/material.dart';

import 'cue_keeper_engine.dart';

class CueKeeperPage extends StatefulWidget {
  const CueKeeperPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctRounds, int missedIntentions) onSessionEnd;

  @override
  State<CueKeeperPage> createState() => _CueKeeperPageState();
}

class _CueKeeperPageState extends State<CueKeeperPage> {
  static const Color _ink = Color(0xFF3D526F);
  static const List<String> _names = ['moon', 'leaf', 'flower', 'star'];
  static const List<IconData> _icons = [
    Icons.nightlight_round,
    Icons.eco_rounded,
    Icons.local_florist_rounded,
    Icons.star_rounded,
  ];
  static const List<Color> _colors = [
    Color(0xFF8C86D2),
    Color(0xFF69B59A),
    Color(0xFFE89993),
    Color(0xFFE6B04D),
  ];

  late CueKeeperSession game;
  int _revision = 0;
  bool _reported = false;
  String _message = 'Watch the stream and remember your intention.';

  @override
  void initState() {
    super.initState();
    _resetSession();
  }

  void _resetSession() {
    game = CueKeeperSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision
          : widget.floor! * 2027 + _revision,
    );
    _reported = false;
    _message = 'Watch the stream and remember your intention.';
  }

  String get _ordinal => game.targetOccurrence == 2 ? 'second' : 'third';

  void _nextCue() {
    final previousMisses = game.mistakes;
    final result = game.nextCue();
    if (result == CueKeeperAdvanceResult.invalid) return;
    setState(() {
      _message = switch (result) {
        CueKeeperAdvanceResult.invalid => _message,
        CueKeeperAdvanceResult.cueRevealed => game.mistakes > previousMisses
            ? 'That intention passed. Keep watching the stream.'
            : 'Keep watching; act only at the remembered cue.',
        CueKeeperAdvanceResult.streamComplete => game.finished
            ? (game.passed
                ? 'Session passed · ${game.correctRounds} intentions remembered.'
                : 'Keep practicing · ${game.correctRounds} intentions remembered.')
            : (game.lastRoundCorrect
                ? 'Intention remembered! Ready for the next one?'
                : 'Intention missed. Reset and try the next one.'),
      };
    });
    if (game.finished) _reportSession();
  }

  void _actNow() {
    final result = game.actNow();
    if (result == CueKeeperActionResult.invalid) return;
    setState(() {
      _message = result == CueKeeperActionResult.correct
          ? 'Well remembered — continue through the stream.'
          : 'Too soon. Continue the stream and try the next intention.';
    });
  }

  void _reportSession() {
    if (_reported) return;
    _reported = true;
    widget.onSessionEnd(game.correctRounds, game.mistakes);
    if (widget.floor != null && game.passed) widget.onComplete();
  }

  void _nextRound() {
    if (!game.nextRound()) return;
    setState(() => _message = 'Keep the new intention in mind.');
  }

  void _playAgain() {
    setState(() {
      _revision++;
      _resetSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedRound = game.finished
        ? CueKeeperSession.roundCount
        : game.round + 1;
    final canAct = !game.finished &&
        !game.roundComplete &&
        game.cueIndex >= 0 &&
        !game.actionResolved;
    final nextCueLabel = game.cueIndex < 0
        ? 'START STREAM'
        : game.cueIndex == CueKeeperSession.cuesPerRound - 1
            ? 'END STREAM'
            : 'NEXT CUE';
    final centerIcon = game.currentSymbol == null
        ? Icons.visibility_rounded
        : _icons[game.currentSymbol!];
    final centerColor = game.currentSymbol == null
        ? const Color(0xFFAAA9C6)
        : _colors[game.currentSymbol!];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      appBar: AppBar(
        toolbarHeight: 48,
        foregroundColor: _ink,
        backgroundColor: const Color(0xFFF6F7FF),
        title: const Text('Cue Keeper',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        color: Color(0xFF7F89A7),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE1F3ED),
                    Color(0xFFE9E9FC),
                    Color(0xFFFFEEDF),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: Color(0xFF7B80C4), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Hold an intention through a cue stream',
                          style: TextStyle(
                              color: _ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900)),
                    ),
                    Text('ROUND $displayedRound / ${CueKeeperSession.roundCount}',
                        style: const TextStyle(
                            color: Color(0xFF737CA5),
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    game.cueIndex < 0
                        ? 'When the ${_names[game.targetSymbol]} appears for the $_ordinal time, tap ACT NOW.'
                        : 'Watch each cue and remember your delayed action.',
                    key: const ValueKey('cue-keeper-instruction'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _ink, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          key: const ValueKey('cue-keeper-stage'),
                          decoration: BoxDecoration(
                            color: const Color(0xDFFFFFFF),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                                color: const Color(0xFFC6D5E5), width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F657AA4),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                game.cueIndex < 0
                                    ? 'READY'
                                    : 'CUE ${game.cueIndex + 1} / ${CueKeeperSession.cuesPerRound}',
                                style: const TextStyle(
                                    color: Color(0xFF7D86A3),
                                    fontSize: 11,
                                    letterSpacing: 1.3,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 136,
                                height: 136,
                                decoration: BoxDecoration(
                                  color: centerColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: centerColor.withValues(alpha: 0.42),
                                      width: 2.5),
                                ),
                                alignment: Alignment.center,
                                child: Icon(centerIcon,
                                    size: 82, color: centerColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                game.currentSymbol == null
                                    ? 'Tap START STREAM when ready'
                                    : 'Notice each cue, then move on',
                                style: const TextStyle(
                                    color: Color(0xFF71819A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 34,
                    child: Center(
                      child: Text(
                        game.finished
                            ? '${game.mistakes} missed or early actions'
                            : _message,
                        key: const ValueKey('cue-keeper-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          key: const ValueKey('cue-keeper-act'),
                          onPressed: canAct ? _actNow : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9A6D36),
                            side: const BorderSide(
                                color: Color(0xFFE2B66A), width: 2),
                            backgroundColor: const Color(0xFFFFF6E8),
                          ),
                          child: const Text('ACT NOW',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          key: const ValueKey('cue-keeper-next'),
                          onPressed: game.finished
                              ? (widget.floor == null || !game.passed
                                  ? _playAgain
                                  : null)
                              : game.roundComplete
                                  ? _nextRound
                                  : _nextCue,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF817BC7),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFB8B4CF),
                            disabledForegroundColor: Colors.white,
                          ),
                          child: Text(
                            game.finished
                                ? (widget.floor != null && game.passed
                                    ? 'LEVEL COMPLETE'
                                    : 'PLAY AGAIN')
                                : game.roundComplete
                                    ? 'NEXT INTENTION'
                                    : nextCueLabel,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
