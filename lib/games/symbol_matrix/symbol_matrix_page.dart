import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'symbol_matrix_engine.dart';

class SymbolMatrixPage extends StatefulWidget {
  const SymbolMatrixPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<SymbolMatrixPage> createState() => _SymbolMatrixPageState();
}

class _SymbolMatrixPageState extends State<SymbolMatrixPage> {
  static const Color _ink = Color(0xFF3B5272);
  static const List<Color> _colors = [
    Color(0xFFE99591),
    Color(0xFF71BDA7),
    Color(0xFF8A86D3),
    Color(0xFFE9B550),
  ];
  static const List<IconData> _shapes = [
    Icons.circle_rounded,
    Icons.change_history_rounded,
    Icons.square_rounded,
    Icons.diamond_rounded,
  ];

  late SymbolMatrixSession game;
  int _revision = 0;
  bool _reported = false;
  String _message = 'Look for the same change across rows and columns.';

  @override
  void initState() {
    super.initState();
    _restartSession();
  }

  void _restartSession() {
    game = SymbolMatrixSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision
          : widget.floor! * 2027 + _revision,
    );
    _reported = false;
    _message = 'Look for the same change across rows and columns.';
  }

  void _choose(int index) {
    if (_reported || game.complete || game.roundComplete) return;
    final result = game.answer(index);
    if (result == MatrixAnswerResult.invalid) return;
    setState(() {
      _message = switch (result) {
        MatrixAnswerResult.correct => 'Correct — the pattern continues!',
        MatrixAnswerResult.incorrect => 'Not quite. Study the rows and columns.',
        MatrixAnswerResult.sessionComplete => game.passed
            ? 'Session passed — ${game.correctAnswers} of 6 solved.'
            : 'Keep practicing — ${game.correctAnswers} of 6 solved.',
        MatrixAnswerResult.invalid => _message,
      };
    });
    if (result == MatrixAnswerResult.sessionComplete) _reportSession();
  }

  void _reportSession() {
    if (_reported) return;
    _reported = true;
    widget.onSessionEnd(game.correctAnswers, game.mistakes);
    if (widget.floor != null && game.passed) widget.onComplete();
  }

  void _nextRound() {
    if (!game.nextRound()) return;
    setState(() => _message = 'Find the missing tile in this matrix.');
  }

  void _playAgain() {
    setState(() {
      _revision++;
      _restartSession();
    });
  }

  Widget _symbol(MatrixSymbol symbol, double maxSize) {
    final iconSize = math.min(
      maxSize * 0.82,
      maxSize * 0.82 / symbol.count,
    ).clamp(13.0, 30.0).toDouble();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < symbol.count; i++)
          RotatedBox(
            quarterTurns: symbol.rotation,
            child: Icon(
              _shapes[symbol.shape],
              size: iconSize,
              color: _colors[symbol.color],
            ),
          ),
      ],
    );
  }

  Widget _tile(MatrixSymbol symbol, {required bool missing}) {
    if (missing) {
      return Container(
        key: const ValueKey('matrix-missing-cell'),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E5FC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFA9A2DF), width: 2),
        ),
        alignment: Alignment.center,
        child: const Text('?',
            style: TextStyle(
                color: Color(0xFF7972BC),
                fontSize: 28,
                fontWeight: FontWeight.w900)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFC9D5E8), width: 1.3),
      ),
      child: LayoutBuilder(
        builder: (context, bounds) => Center(
          child: _symbol(symbol, math.min(bounds.maxWidth, bounds.maxHeight)),
        ),
      ),
    );
  }

  Widget _matrixBoard() {
    return LayoutBuilder(builder: (context, bounds) {
      final side = math.min(bounds.maxWidth, bounds.maxHeight);
      return Center(
        child: SizedBox.square(
          key: const ValueKey('symbol-matrix-board'),
          dimension: side,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: game.cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final symbol = game.cells[index];
              return _tile(symbol ?? const MatrixSymbol(
                shape: 0, color: 0, count: 1, rotation: 0,
              ), missing: symbol == null);
            },
          ),
        ),
      );
    });
  }

  Widget _choiceCard(int index) {
    final symbol = game.options[index];
    final answered = game.roundComplete || game.complete;
    final selected = game.selectedOption == index;
    final isCorrect = index == game.answerIndex;
    final borderColor = answered && isCorrect
        ? const Color(0xFF72B99A)
        : answered && selected
            ? const Color(0xFFE39B96)
            : const Color(0xFFBFCCE2);
    return Material(
      color: selected && !answered
          ? const Color(0xFFE5E2FC)
          : const Color(0xF7FFFFFF),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        key: ValueKey('matrix-choice-$index'),
        onTap: answered ? null : () => _choose(index),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor, width: selected ? 2.4 : 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF0FA),
                  shape: BoxShape.circle,
                ),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 7),
              Flexible(child: _symbol(symbol, 35)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedRound = game.complete
        ? SymbolMatrixSession.roundCount
        : game.round + 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FF),
      appBar: AppBar(
        toolbarHeight: 48,
        foregroundColor: _ink,
        backgroundColor: const Color(0xFFF7F7FF),
        title: const Text('Symbol Matrix',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        color: Color(0xFF7D89A7),
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
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDFF2F1),
                    Color(0xFFE8E8FC),
                    Color(0xFFFFEEDC),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.grid_view_rounded,
                        color: Color(0xFF777CC1), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Find the missing tile',
                          style: TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w900)),
                    ),
                    Text('ROUND $displayedRound / ${SymbolMatrixSession.roundCount}',
                        style: const TextStyle(
                            color: Color(0xFF737CA5),
                            fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 7),
                  const Text(
                    'Each trait changes steadily across rows and columns.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _ink, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Expanded(child: _matrixBoard()),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 106,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: game.options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 7,
                        mainAxisExtent: 48,
                      ),
                      itemBuilder: (context, index) => _choiceCard(index),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 28,
                    child: Center(
                      child: Text(
                        game.complete
                            ? (game.passed
                                ? 'Session passed · ${game.mistakes} misses'
                                : 'Session ended · ${game.mistakes} misses')
                            : _message,
                        key: const ValueKey('symbol-matrix-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('symbol-matrix-action'),
                      onPressed: game.complete
                          ? (widget.floor == null || !game.passed
                              ? _playAgain
                              : null)
                          : (game.roundComplete ? _nextRound : null),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF817BC7),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB8B4CF),
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Text(
                        game.complete
                            ? (widget.floor != null && game.passed
                                ? 'LEVEL COMPLETE'
                                : 'PLAY AGAIN')
                            : game.roundComplete
                                ? 'NEXT MATRIX'
                                : 'CHOOSE A TILE',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
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
