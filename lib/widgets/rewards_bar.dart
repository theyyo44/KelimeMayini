// widgets/rewards_bar.dart
import 'package:flutter/material.dart';
import '../models/reward.dart';

class RewardsBar extends StatelessWidget {
  final List<Reward> rewards;
  final bool myTurn;
  final Function(Reward) onUseReward;

  const RewardsBar({
    super.key,
    required this.rewards,
    required this.myTurn,
    required this.onUseReward,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty || !myTurn) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Text(
            "Ödüller",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rewards.map((reward) {
              return GestureDetector(
                onTap: () => onUseReward(reward),
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Tooltip(
                    message: reward.getDescription(),
                    child: Icon(
                      _getRewardIcon(reward.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.areaRestriction:
        return Icons.block;
      case RewardType.letterRestriction:
        return Icons.text_fields;
      case RewardType.extraMove:
        return Icons.add_circle;
    }
  }
}