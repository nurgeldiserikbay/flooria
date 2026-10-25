import 'package:flutter/material.dart';
import 'code_breaker_engine.dart';

/// Compact mobile deduction game; independent from app shell and persistence.
class CodeBreakerPage extends StatefulWidget {
  const CodeBreakerPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});

  final int? floor;
  final VoidCallback onComplete;
  final void Function(bool solved, int attempts) onSessionEnd;

  @override
  State<CodeBreakerPage> createState() => _CodeBreakerPageState();
}

class _CodeBreakerPageState extends State<CodeBreakerPage> {
  late CodeBreakerSession game;
  final List<int> entry = [];
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    game = CodeBreakerSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 13007 + revision);
    entry.clear();
    reported = false;
  }

  void _pick(int digit) {
    if (game.finished || entry.length == 3 || entry.contains(digit)) return;
    setState(() => entry.add(digit));
  }

  void _submit() {
    if (reported || entry.length != 3) return;
    final result = game.submit(entry);
    if (result == null) return;
    setState(() => entry.clear());
    if (!game.finished) return;
    reported = true;
    widget.onSessionEnd(game.solved, game.attempts);
    if (game.solved && widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF344770);
    const accents = <Color>[
      Color(0xFF88C7F5), Color(0xFFFFBF98),
      Color(0xFFC0A5F1), Color(0xFF8BDBAE),
      Color(0xFFFFDB81),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF1EAFD),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Code Breaker',
          style: TextStyle(fontWeight: FontWeight.w900)),
        foregroundColor: textColor,
        backgroundColor: const Color(0xFFF9F6FF),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 12, color: Color(0xFF7975A7))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFD5E9FF), Color(0xFFE9DDFB),
              Color(0xFFFFEBD9)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.lock_open_rounded,
                color: Color(0xFF7974C5), size: 23),
              const SizedBox(width: 8),
              const Expanded(child: Text('Crack the 3-symbol code',
                style: TextStyle(color: textColor,
                  fontWeight: FontWeight.w900, fontSize: 14))),
              Text('${game.attempts} / ${game.maxAttempts}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF7378AB))),
            ]),
            const SizedBox(height: 7),
            const Text('Exact = right symbol & position • Swap = right symbol, wrong position',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6576A5), fontSize: 11)),
            const SizedBox(height: 8),
            Expanded(child: Column(children: [
              for (var i = 0; i < game.maxAttempts; i++)
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xDFFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCAD3F0))),
                    child: Row(children: [
                      Text('${i + 1}', style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900,
                        color: Color(0xFF919BC1))),
                      const SizedBox(width: 8),
                      for (var j = 0; j < 3; j++)
                        Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i < game.guesses.length
                                ? accents[game.guesses[i].digits[j] - 1]
                                : const Color(0xFFECEFFA),
                              borderRadius: BorderRadius.circular(10)),
                            child: i < game.guesses.length
                              ? Text('${game.guesses[i].digits[j]}',
                                style: const TextStyle(
                                  color: textColor, fontSize: 18,
                                  fontWeight: FontWeight.w900))
                              : null))),
                      const SizedBox(width: 8),
                      SizedBox(width: 102, child: i < game.guesses.length
                        ? Column(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Exact ${game.guesses[i].feedback.exact}',
                              style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF379D88))),
                            Text('Swap ${game.guesses[i].feedback.misplaced}',
                              style: const TextStyle(fontSize: 11,
                                color: Color(0xFF736A9B))),
                          ])
                        : const SizedBox.shrink()),
                    ]),
                  ),
                )),
            ])),
            const SizedBox(height: 7),
            if (game.finished)
              Text(game.solved ? 'Code unlocked!' : 'No attempts left. Try again!',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: textColor)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  width: 46, height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i < entry.length
                      ? accents[entry[i] - 1]
                      : const Color(0xFFF8FAFF),
                    border: Border.all(color: const Color(0xFFA4B7DF),
                      width: 2),
                    borderRadius: BorderRadius.circular(13)),
                  child: Text(i < entry.length ? '${entry[i]}' : '?',
                    style: const TextStyle(color: textColor,
                      fontSize: 22, fontWeight: FontWeight.w900))),
            ]),
            Row(children: [
              for (var i = 1; i <= 5; i++)
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(height: 54, child: FilledButton(
                    key: ValueKey('code-digit-$i'),
                    onPressed: game.finished || entry.contains(i)
                      ? null : () => _pick(i),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: textColor,
                      backgroundColor: accents[i - 1],
                      disabledBackgroundColor: const Color(0xFFDCE0EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                    child: Text('$i', style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w900))))),
            ]),
            const SizedBox(height: 9),
            Row(children: [
              IconButton(
                tooltip: 'Undo symbol',
                onPressed: entry.isEmpty ? null
                  : () => setState(() => entry.removeLast()),
                icon: const Icon(Icons.backspace_outlined, color: textColor)),
              Expanded(child: SizedBox(height: 45,
                child: FilledButton(
                  onPressed: game.finished
                    ? () => setState(() { revision++; _newGame(); })
                    : entry.length == 3 ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7775CA),
                    foregroundColor: Colors.white),
                  child: Text(game.finished ? 'PLAY AGAIN' : 'CHECK CODE',
                    style: const TextStyle(fontWeight: FontWeight.w900))))),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() { revision++; _newGame(); }),
                icon: const Icon(Icons.refresh_rounded, color: textColor)),
            ]),
          ]),
        ),
      ))),
    );
  }
}
