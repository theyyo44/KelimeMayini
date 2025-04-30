// widgets/game_top_bar.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GameTopBar extends StatelessWidget {
  final int myScore;
  final int opponentScore;
  final int remainingLettersCount;
  final bool myTurn;

  const GameTopBar({
    super.key,
    required this.myScore,
    required this.opponentScore,
    required this.remainingLettersCount,
    required this.myTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: GameStyles.primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "👤 Sen",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "🏆 $myScore",
                    style: GameStyles.scoreStyle,
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    "🔤 Kalan",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "$remainingLettersCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "🤖 Rakip",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "🏆 $opponentScore",
                    style: GameStyles.scoreStyle,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: myTurn ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              myTurn ? "Senin sıran!" : "Rakibin sırası...",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}