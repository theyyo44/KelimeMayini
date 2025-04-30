// screens/dialogs/surrender_dialog.dart
import 'package:flutter/material.dart';

class SurrenderDialog extends StatelessWidget {
  const SurrenderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Teslim Ol"),
      content: const Text(
          "Gerçekten teslim olmak istiyor musun? Bu oyunu kaybetmiş sayılacaksın."
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Vazgeç"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Teslim Ol"),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  /// Dialog kutusunu gösterir ve sonucu döndürür
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const SurrenderDialog(),
    );
  }
}