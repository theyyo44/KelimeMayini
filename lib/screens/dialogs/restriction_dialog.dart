import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class RestrictionDialog extends StatelessWidget {
  final String restrictionType; // 'area' veya 'letter'
  final String side; // area restriction için 'left' veya 'right'
  final List<String> restrictedLetters; // letter restriction için kısıtlı harfler

  const RestrictionDialog({
    super.key,
    required this.restrictionType,
    this.side = '',
    this.restrictedLetters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          restrictionType == 'area'
              ? "Bölge Kısıtlaması Aktif!"
              : "Harf Kısıtlaması Aktif!"
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            restrictionType == 'area'
                ? Icons.block
                : Icons.text_fields,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            restrictionType == 'area'
                ? "Bu hamle için ${side == 'left' ? 'SOL' : 'SAĞ'} tarafa harf koyamazsın!"
                : "Bu hamle için aşağıdaki harfleri kullanamazsın:",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (restrictionType == 'letter' && restrictedLetters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: restrictedLetters.map((letter) {
                  return Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            "Bu kısıtlama bir tur boyunca geçerlidir. Bir sonraki hamlemde otomatik olarak kaldırılacaktır.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: GameStyles.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("Anladım"),
        ),
      ],
    );
  }

  /// Dialog kutusunu gösterir
  static Future<void> show({
    required BuildContext context,
    required String restrictionType,
    String side = '',
    List<String> restrictedLetters = const [],
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RestrictionDialog(
        restrictionType: restrictionType,
        side: side,
        restrictedLetters: restrictedLetters,
      ),
    );
  }
}