import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class JokerSelectionDialog extends StatelessWidget {
  static Future<String?> show(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => JokerSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Türkçe harfler listesi
    final List<String> turkishLetters = [
      'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
      'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
      'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "JOKER Hangi Harf Olsun?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(maxHeight: 400),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: turkishLetters.length,
                itemBuilder: (context, index) {
                  final letter = turkishLetters[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, letter),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}