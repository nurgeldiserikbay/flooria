import 'package:flutter/material.dart';

import 'rule_relay_engine.dart';

class RuleRelayPage extends StatefulWidget {
  const RuleRelayPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int total) onSessionEnd;

  @override
  State<RuleRelayPage> createState() => _RuleRelayPageState();
}

class _RuleRelayPageState extends State<RuleRelayPage> {
  static const _paper = Color(0xFFF5F8FF);
  static const _ink = Color(0xFF34436B);
  static const _muted = Color(0xFF7885A7);
  static const _violet = Color(0xFF7773C9);

  late RuleRelaySession session;
  int _revision = 0;
  bool _reported = false;
  bool? _lastWasCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _lastWasCorrect = null;
    session = RuleRelaySession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 7919 + _revision++,
    );
  }

  void _choose(int index) {
    if (session.finished || _reported) return;
    final wasCorrect = index == session.current.correctIndex;
    if (!session.answer(index)) return;
    setState(() => _lastWasCorrect = wasCorrect);
    if (session.finished) _finish();
  }

  void _finish() {
    if (_reported || !session.finished) return;
    _reported = true;
    widget.onSessionEnd(session.correct, RuleRelaySession.roundCount);
    if (session.passed && widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final current = session.current;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Rule Relay',
            style: TextStyle(fontWeight: FontWeight.w900)),
        foregroundColor: _ink,
        backgroundColor: _paper,
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        fontSize: 12,
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          color: _violet, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Match the card. Watch for a new rule.',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _ink,
                                fontSize: 14)),
                      ),
                      Text(
                        complete
                            ? '${session.correct} / 12'
                            : '${session.round + 1} / 12',
                        style: const TextStyle(
                            color: _violet, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE1E6F5),
                      color: _violet,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Expanded(
                    child: complete
                        ? _ResultsPanel(
                            session: session,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              _RuleBanner(rule: current.rule),
                              const SizedBox(height: 12),
                              const Text('TARGET CARD',
                                  style: TextStyle(
                                      color: _muted,
                                      letterSpacing: 1.4,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Center(
                                  child: _CardFace(
                                    card: current.target,
                                    large: true,
                                    label: 'Target card',
                                  ),
                                ),
                              ),
                              Text(
                                _lastWasCorrect == null
                                    ? 'PICK THE CARD WITH THE SAME ${_ruleName(current.rule)}'
                                    : _lastWasCorrect!
                                        ? 'NICE SWITCH! KEEP GOING'
                                        : 'RULES CAN CHANGE — LOOK AGAIN',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: _muted,
                                    letterSpacing: .8,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (var index = 0;
                                      index < current.options.length;
                                      index++) ...[
                                    if (index > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: _OptionButton(
                                        key: ValueKey('rule-option-$index'),
                                        card: current.options[index],
                                        label: 'Option ${index + 1}',
                                        onPressed: () => _choose(index),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Score ${session.correct}  •  rule changes every 3 cards',
                                style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
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

class _RuleBanner extends StatelessWidget {
  const _RuleBanner({required this.rule});

  final RelayRule rule;

  @override
  Widget build(BuildContext context) {
    final (name, icon) = switch (rule) {
      RelayRule.color => ('COLOR', Icons.palette_rounded),
      RelayRule.shape => ('SHAPE', Icons.category_rounded),
      RelayRule.quantity => ('QUANTITY', Icons.format_list_numbered_rounded),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1CDF8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF6F69BB), size: 20),
          const SizedBox(width: 8),
          Text('MATCH BY $name',
              style: const TextStyle(
                  color: Color(0xFF59559E),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.card,
    required this.label,
    required this.onPressed,
  });

  final RelayCard card;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label, ${_cardDescription(card)}',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 112,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD8E0F1), width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0D34436B),
                      blurRadius: 8,
                      offset: Offset(0, 3)),
                ],
              ),
              child: _CardFace(card: card, label: label),
            ),
          ),
        ),
      );
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.label,
    this.large = false,
  });

  static const _colors = <Color>[
    Color(0xFFF27E84),
    Color(0xFF61B8A0),
    Color(0xFF6E9CE8),
    Color(0xFFF0B84F),
  ];
  static const _shapes = <IconData>[
    Icons.circle_rounded,
    Icons.change_history_rounded,
    Icons.square_rounded,
    Icons.diamond_rounded,
  ];

  final RelayCard card;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 25.0 : 21.0;
    return Semantics(
      label: '$label, ${_cardDescription(card)}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < card.quantity; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                _shapes[card.shape],
                color: _colors[card.color],
                size: iconSize,
                shadows: const [
                  Shadow(color: Color(0x2634436B), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session, required this.onRetry});

  final RuleRelaySession session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFDDE4F5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                session.passed ? Icons.auto_awesome_rounded : Icons.refresh_rounded,
                color: session.passed
                    ? const Color(0xFFF0B84F)
                    : const Color(0xFF7773C9),
                size: 44,
              ),
              const SizedBox(height: 10),
              Text(
                session.passed ? 'Great rule switching!' : 'Keep practicing',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF34436B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                'You matched ${session.correct} of ${RuleRelaySession.roundCount} cards.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF7885A7), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('PLAY AGAIN'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7773C9),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
}

String _cardDescription(RelayCard card) {
  const colors = ['coral', 'mint', 'blue', 'gold'];
  const shapes = ['circle', 'triangle', 'square', 'diamond'];
  return '${colors[card.color]} ${shapes[card.shape]}, quantity ${card.quantity}';
}

String _ruleName(RelayRule rule) => switch (rule) {
      RelayRule.color => 'COLOR',
      RelayRule.shape => 'SHAPE',
      RelayRule.quantity => 'QUANTITY',
    };
