// widgets/game_actions.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GameActions extends StatelessWidget {
  final bool myTurn;
  final bool isWordValid;
  final String currentWord;
  final int currentWordScore;
  final List<Map<String, dynamic>> allWords; // Tüm oluşturulan kelimelerin listesi
  final VoidCallback onConfirm;
  final VoidCallback onPass;
  final VoidCallback onSurrender;

  const GameActions({
    super.key,
    required this.myTurn,
    required this.isWordValid,
    required this.currentWord,
    required this.currentWordScore,
    this.allWords = const [], // Varsayılan olarak boş liste
    required this.onConfirm,
    required this.onPass,
    required this.onSurrender,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (currentWord.isNotEmpty)
          GestureDetector(
            onTap: () {
              if (allWords.isNotEmpty) {
                _showWordsDialog(context);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isWordValid ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Kelime: $currentWord",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Puan: $currentWordScore",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  if (!isWordValid)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "Dikkat: Oluşturduğunuz kelimelerden en az biri geçersiz!",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (allWords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.touch_app,
                            color: Colors.white70,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Tüm kelimeleri görmek için tıklayın",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                "Onayla",
                Icons.check,
                Colors.green,
                onConfirm,
                myTurn && isWordValid,
              ),
              _actionButton(
                "Pas",
                Icons.pause,
                Colors.orange,
                onPass,
                myTurn,
              ),
              _actionButton(
                "Teslim Ol",
                Icons.flag,
                Colors.redAccent,
                onSurrender,
                myTurn,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      bool isEnabled,
      ) {
    return ElevatedButton.icon(
      style: GameStyles.actionButtonStyle(color),
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }

  void _showWordsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WordsListDialog(words: allWords),
    );
  }
}

/// Oluşturulan kelimeleri gösteren dialog
class WordsListDialog extends StatelessWidget {
  final List<Map<String, dynamic>> words;

  const WordsListDialog({
    super.key,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    // Kelimeleri geçerli ve geçersiz olarak ayır
    final validWords = words.where((w) => w['isValid'] == true).toList();
    final invalidWords = words.where((w) => w['isValid'] == false).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Oluşturulan Kelimeler",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Kelimelerin listesi
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (validWords.isNotEmpty) ...[
                    const Text(
                      "Geçerli Kelimeler:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...validWords.map((word) => _buildWordItem(
                      word['word'],
                      word['score'],
                      true,
                      word['isMain'] == true,
                    )),
                    const SizedBox(height: 16),
                  ],

                  if (invalidWords.isNotEmpty) ...[
                    const Text(
                      "Geçersiz Kelimeler:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...invalidWords.map((word) => _buildWordItem(
                      word['word'],
                      word['score'],
                      false,
                      word['isMain'] == true,
                    )),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kapatma butonu
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: GameStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordItem(String word, int score, bool isValid, bool isMain) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            word,
            style: TextStyle(
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            "$score puan",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isValid ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}