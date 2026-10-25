import 'dart:math';

import 'package:flutter/material.dart';

import 'word_forge_engine.dart';

class WordForgePage extends StatefulWidget {
  const WordForgePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int elapsedMillis, int mistakes) onSessionEnd;

  @override
  State<WordForgePage> createState() => _WordForgePageState();
}

class _WordForgePageState extends State<WordForgePage> {
  late WordForgeSession session;
  final Stopwatch _clock = Stopwatch();
  int _revision = 0;
  bool _rewarded = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _clock
      ..stop()
      ..reset();
    _rewarded = false;
    _feedback = null;
    _feedbackIsError = false;
    session = WordForgeSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 32452843 + _revision++,
    );
  }

  void _select(int index) {
    if (!session.select(index)) return;
    if (!_clock.isRunning) _clock.start();
    setState(() {
      _feedback = null;
      _feedbackIsError = false;
    });
  }

  void _undo() {
    if (!session.removeLast()) return;
    setState(() {
      _feedback = null;
      _feedbackIsError = false;
    });
  }

  Future<void> _submit() async {
    if (session.finished) return;
    final result = session.submit();
    setState(() {
      _feedbackIsError = result == WordForgeSubmitResult.incorrect;
      _feedback = switch (result) {
        WordForgeSubmitResult.incomplete => 'Choose every letter before checking.',
        WordForgeSubmitResult.incorrect => 'Not quite. Remove a letter and try again.',
        WordForgeSubmitResult.roundComplete => 'That is it! Here comes the next clue.',
        WordForgeSubmitResult.sessionComplete => 'All three words found!',
      };
    });
    if (!session.finished) return;
    _clock.stop();
    if (_rewarded) return;
    _rewarded = true;
    widget.onSessionEnd(_clock.elapsedMilliseconds, session.mistakes);
    if (widget.floor == null) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Word master!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You solved all three clues in ${_clock.elapsedMilliseconds ~/ 1000}s.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('CONTINUE'),
        )],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(advance == true);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = session.puzzle;
    final selected = session.selectedIndices.toSet();
    final complete = session.finished;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Word Forge', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _cream,
        foregroundColor: _ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: _muted)),
            )),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.spellcheck_rounded, color: _orange, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Build the word from its clue',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text('${session.round + (complete ? 0 : 1)} / ${session.roundCount}',
                style: const TextStyle(color: _orange, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFFFE2CA),
              color: _orange,
            )),
            const SizedBox(height: 12),
            if (complete)
              Expanded(child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 64, color: _orange),
                  const SizedBox(height: 10),
                  const Text('Three words found!', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 8),
                  Text('Mistakes: ${session.mistakes}', style: const TextStyle(
                    color: _muted, fontWeight: FontWeight.w700)),
                  if (widget.floor == null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(_startSession),
                      style: FilledButton.styleFrom(backgroundColor: _orange,
                        foregroundColor: Colors.white),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('PLAY AGAIN'),
                    ),
                  ],
                ],
              )))
            else ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 76, maxHeight: 100),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3D4B9), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(puzzle.clue, textAlign: TextAlign.center,
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontWeight: FontWeight.w700,
                    fontSize: 15, height: 1.25)),
              ),
              const SizedBox(height: 12),
              const Text('YOUR WORD', style: TextStyle(fontSize: 10,
                letterSpacing: 1.2, fontWeight: FontWeight.w900, color: _muted)),
              const SizedBox(height: 7),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 5,
                children: List<Widget>.generate(puzzle.answer.length, (slot) {
                  final hasLetter = slot < session.draft.length;
                  return Container(
                    width: min(40.0,
                      (MediaQuery.sizeOf(context).width - 60) / puzzle.answer.length)
                        .clamp(30.0, 40.0).toDouble(),
                    height: 46,
                    decoration: BoxDecoration(
                      color: hasLetter ? const Color(0xFFFFE2C6) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8C6A8), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(hasLetter ? session.draft[slot] : '',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink)),
                  );
                }),
              ),
              const SizedBox(height: 7),
              SizedBox(height: 20, child: Text(_feedback ?? 'Tap the letters in the right order.',
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12,
                  color: _feedbackIsError ? _red : _muted,
                  fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Expanded(child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 2),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: puzzle.letters.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8,
                  childAspectRatio: 1.38,
                ),
                itemBuilder: (context, index) {
                  final used = selected.contains(index);
                  return Semantics(button: true,
                    label: used ? 'Letter ${puzzle.letters[index]}, selected' : 'Letter ${puzzle.letters[index]}',
                    child: Material(
                      color: used ? const Color(0xFFEDE2D7) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: used ? null : () => _select(index),
                        child: Center(child: Text(puzzle.letters[index],
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900,
                            color: used ? const Color(0xFFC4AD98) : _ink))),
                      ),
                    ),
                  );
                },
              )),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('${session.selectedIndices.length} / ${puzzle.answer.length} letters',
                  style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700))),
                OutlinedButton.icon(
                  onPressed: session.selectedIndices.isEmpty ? null : _undo,
                  style: OutlinedButton.styleFrom(foregroundColor: _orange,
                    side: const BorderSide(color: Color(0xFFEAC7A8))),
                  icon: const Icon(Icons.backspace_outlined, size: 17),
                  label: const Text('UNDO'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('CHECK'),
                ),
              ]),
            ],
          ]),
        ),
      ))),
    );
  }

  @override
  void dispose() {
    _clock.stop();
    super.dispose();
  }
}

const _cream = Color(0xFFFFF4E5);
const _ink = Color(0xFF76513D);
const _muted = Color(0xFF9B7B69);
const _orange = Color(0xFFE99A5E);
const _red = Color(0xFFCB716A);
