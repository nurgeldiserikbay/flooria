import 'package:flutter/material.dart';

import 'semantic_sort_engine.dart';

class SemanticSortPage extends StatefulWidget {
  const SemanticSortPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<SemanticSortPage> createState() => _SemanticSortPageState();
}

class _SemanticSortPageState extends State<SemanticSortPage> {
  late SemanticSortSession session;
  int _revision = 0;
  bool _reported = false;
  String? _feedback;
  bool? _lastWasCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 32452843 + _revision;
    _revision++;
    session = SemanticSortSession(seed: seed, level: level);
    _reported = false;
    _feedback = null;
    _lastWasCorrect = null;
  }

  void _choose(CategorySide side) {
    final result = session.answer(side);
    if (result == CategoryAnswer.invalid) return;
    setState(() {
      _lastWasCorrect = result == CategoryAnswer.correct;
      _feedback = _lastWasCorrect!
          ? 'That belongs in this group.'
          : 'Not quite — read the category names closely.';
    });
  }

  void _continue() {
    if (!session.advance()) return;
    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (widget.floor != null && session.passed) widget.onComplete();
    }
    setState(() {
      _feedback = null;
      _lastWasCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.finished;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Semantic Sort',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
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
                      finished
                          ? 'Sorting complete'
                          : 'Category ${session.roundIndex + 1} of ${SemanticSortSession.roundCount}',
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
                      backgroundColor: const Color(0xFFE7ECE8),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: finished
                        ? _SortResults(
                            correct: session.correctAnswers,
                            total: session.totalItems,
                            mistakes: session.mistakes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : _sortingArea(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortingArea() {
    final round = session.currentRound;
    final item = session.currentItem;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _softLilac,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Text(
            'Place each word in the group it belongs to.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Card ${session.itemIndex + 1} of ${session.itemsPerRound}',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 170),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _edge, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D53675D),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell_rounded, color: _purple, size: 28),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label.toUpperCase(),
                      key: const ValueKey('semantic-sort-item'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Which group?',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        if (!session.answered)
          Row(
            children: [
              Expanded(
                child: _CategoryButton(
                  label: round.leftCategory,
                  side: CategorySide.left,
                  color: _teal,
                  icon: Icons.eco_rounded,
                  onTap: () => _choose(CategorySide.left),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CategoryButton(
                  label: round.rightCategory,
                  side: CategorySide.right,
                  color: _coral,
                  icon: Icons.category_rounded,
                  onTap: () => _choose(CategorySide.right),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: 45,
            child: FilledButton.icon(
              key: const ValueKey('semantic-sort-next'),
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_continueLabel),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        SizedBox(
          height: 21,
          child: Center(
            child: Text(
              _feedback ?? 'Build a streak of correct sorts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _lastWasCorrect == false ? _coral : _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _continueLabel {
    if (session.itemIndex < session.itemsPerRound - 1) return 'NEXT CARD';
    if (session.roundIndex < SemanticSortSession.roundCount - 1) {
      return 'NEXT CATEGORY';
    }
    return 'SEE RESULTS';
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.side,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final CategorySide side;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: ValueKey('semantic-sort-${side.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 98,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 27),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SortResults extends StatelessWidget {
  const _SortResults({
    required this.correct,
    required this.total,
    required this.mistakes,
    required this.passed,
    required this.onRetry,
  });

  final int correct;
  final int total;
  final int mistakes;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.auto_awesome_rounded : Icons.refresh_rounded,
              color: passed ? _teal : _coral,
              size: 62,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Great sorting!' : 'Keep sorting and learning',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct of $total correct · $mistakes misses',
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
              ),
            ),
          ],
        ),
      );
}

const _paper = Color(0xFFFAFBF8);
const _ink = Color(0xFF46504B);
const _muted = Color(0xFF8B9690);
const _teal = Color(0xFF5D9E88);
const _coral = Color(0xFFC97D72);
const _purple = Color(0xFF8274AE);
const _softLilac = Color(0xFFF0ECF8);
const _edge = Color(0xFFE6ECE7);
