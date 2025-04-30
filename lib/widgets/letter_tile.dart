// widgets/letter_tile.dart
import 'package:flutter/material.dart';
import '../models/letter.dart';
import '../utils/constants.dart';

class LetterTile extends StatelessWidget {
  final Letter letter;
  final bool isActive;
  final bool isRestricted;

  const LetterTile({
    super.key,
    required this.letter,
    this.isActive = true,
    this.isRestricted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      // Eğer harf kısıtlı veya aktif değilse sürüklemeyi devre dışı bırak
      data: isActive && !isRestricted ? letter.toMap() : null,
      feedback: _buildTile(isBeingDragged: true),
      childWhenDragging: _buildTile(isEmpty: true),
      child: _buildTile(),
    );
  }

  Widget _buildTile({bool isEmpty = false, bool isBeingDragged = false}) {
    return Container(
      width: 44,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _getTileColor(isEmpty),
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          if (!isEmpty)
            Center(
              child: Text(
                letter.char,
                style: GameStyles.letterStyle,
              ),
            ),
          if (!isEmpty)
            Positioned(
              bottom: 2,
              right: 4,
              child: Text(
                letter.point.toString(),
                style: GameStyles.letterPointStyle,
              ),
            ),
          if (isRestricted && !isEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTileColor(bool isEmpty) {
    if (isEmpty) {
      return Colors.grey.withOpacity(0.3);
    }

    if (isRestricted) {
      return Colors.grey;
    }

    if (letter.isJoker) {
      return Colors.purpleAccent;
    }

    return Colors.amber;
  }
}