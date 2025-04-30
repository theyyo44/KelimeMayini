// screens/dialogs/game_end_dialog.dart
import 'package:flutter/material.dart';
import '../../models/game_state.dart';

class GameEndDialog extends StatelessWidget {
  final bool isWinner;
  final EndReason? endReason;
  final int myScore;
  final int opponentScore;

  const GameEndDialog({
    super.key,
    required this.isWinner,
    required this.endReason,
    required this.myScore,
    required this.opponentScore,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isWinner ? 'Tebrikler! Kazandın!' : 'Oyun Bitti'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              isWinner
                  ? 'Puanın: $myScore\nRakip puanı: $opponentScore'
                  : 'Rakip kazandı.\nPuanın: $myScore\nRakip puanı: $opponentScore'
          ),
          if (endReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '\nBitiş nedeni: ${_getEndReasonText(endReason!)}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Ana menüye dön
          },
          child: const Text('Ana Menüye Dön'),
        ),
      ],
    );
  }

  String _getEndReasonText(EndReason reason) {
    switch (reason) {
      case EndReason.surrender:
        return 'Teslim olma';
      case EndReason.noLetters:
        return 'Harfler tükendi';
      case EndReason.timeOut:
        return 'Süre doldu';
      case EndReason.consecutivePasses:
        return 'Üst üste pas geçme';
      case EndReason.completed:
        return 'Oyun tamamlandı';
    }
  }

  /// Dialog kutusunu gösterir
  static Future<void> show({
    required BuildContext context,
    required bool isWinner,
    required EndReason? endReason,
    required int myScore,
    required int opponentScore,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameEndDialog(
        isWinner: isWinner,
        endReason: endReason,
        myScore: myScore,
        opponentScore: opponentScore,
      ),
    );
  }
}