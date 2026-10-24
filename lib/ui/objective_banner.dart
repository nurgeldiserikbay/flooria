import 'package:flutter/material.dart';
import '../game/game_objective.dart';

/// Compact, animated mission briefing shared by all game modules.
class ObjectiveBanner extends StatelessWidget {
  final GameObjective objective;
  final int progress;
  const ObjectiveBanner({super.key, required this.objective, required this.progress});

  @override
  Widget build(BuildContext context) {
    final achieved = objective.isComplete(progress);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF354F99), Color(0xFF263875)]),
        border: Border.all(color: const Color(0xFF7393E2), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x44234FC2), blurRadius: 8, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(achieved ? Icons.emoji_events_rounded : Icons.flag_rounded,
            color: const Color(0xFF9EEAFF), size: 22),
          const SizedBox(width: 8),
          const Text('NEURON CHALLENGE', style: TextStyle(
            color: Color(0xFF9EEAFF), fontSize: 11,
            letterSpacing: 1.3, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('${progress.clamp(0, objective.target)} / ${objective.target}',
            style: const TextStyle(color: Color(0xFF9EEAFF),
              fontSize: 13, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        Text(objective.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(
          color: Color(0xFFFFFFFF), fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(objective.instruction, style: const TextStyle(
          color: Color(0xFFB8CBEE), fontSize: 12)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: objective.completion(progress)),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFF1A2D62),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7FE8E1)),
            ),
          ),
        ),
      ]),
    );
  }
}
