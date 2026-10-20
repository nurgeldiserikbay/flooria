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
          colors: [Color(0xFFFFF8E8), Color(0xFFFFE4B8)]),
        border: Border.all(color: const Color(0xFFFFD395), width: 2),
        borderRadius: BorderRadius.circular(20),
        border: const Border(bottom: BorderSide(color: Color(0xFFE3AE61), width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(achieved ? Icons.emoji_events_rounded : Icons.flag_rounded,
            color: const Color(0xFF784E63), size: 22),
          const SizedBox(width: 8),
          const Text('FLOOR MISSION', style: TextStyle(
            color: Color(0xFF784E63), fontSize: 11,
            letterSpacing: 1.3, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('${progress.clamp(0, objective.target)} / ${objective.target}',
            style: const TextStyle(color: Color(0xFF784E63),
              fontSize: 13, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        Text(objective.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(
          color: Color(0xFF453951), fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(objective.instruction, style: const TextStyle(
          color: Color(0xFF715F6B), fontSize: 12)),
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
              backgroundColor: const Color(0xFFE4C7A4),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF63BA9A)),
            ),
          ),
        ),
      ]),
    );
  }
}
