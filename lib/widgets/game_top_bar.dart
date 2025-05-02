import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GameTopBar extends StatelessWidget {
  final int myScore;
  final int opponentScore;
  final int remainingLettersCount;
  final bool myTurn;
  final String myUsername;
  final String opponentUsername;
  final int remainingSeconds;

  const GameTopBar({
    super.key,
    required this.myScore,
    required this.opponentScore,
    required this.remainingLettersCount,
    required this.myTurn,
    required this.myUsername,
    required this.opponentUsername,
    required this.remainingSeconds,
  });


  @override
  Widget build(BuildContext context) {
    // Süreyi saat:dakika:saniye formatına dönüştür
    String timeDisplay = "";
    if (remainingSeconds > 3600) {
      final hours = remainingSeconds ~/ 3600;
      final minutes = (remainingSeconds % 3600) ~/ 60;
      final seconds = remainingSeconds % 60;
      timeDisplay = "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      timeDisplay = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: GameStyles.primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kullanıcı (Sen)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👤 $myUsername",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "🏆 $myScore",
                    style: GameStyles.scoreStyle,
                  ),
                ],
              ),

              // Kalan Süre (ortaya alındı)
              Row(
                children: [
                  // Süre - rakipten önce yerleştirdiğimiz için sola kaymış olacak
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: remainingSeconds < 30 ? Colors.red : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: remainingSeconds < 30 ? Colors.red : Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeDisplay,
                          style: TextStyle(
                            color: remainingSeconds < 30 ? Colors.red : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 90), // Süre ile rakip arasındaki boşluk

                  // Rakip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "🤖 $opponentUsername",
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        "🏆 $opponentScore",
                        style: GameStyles.scoreStyle,
                      ),
                    ],
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
              myTurn
                  ? "$myUsername'ın sırası!"
                  : "$opponentUsername'ın sırası...",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Kalan harf sayısı
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "🔤 Kalan Harf: ",
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
          ),
        ],
      ),
    );
  }
}
