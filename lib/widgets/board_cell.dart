// widgets/board_cell.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/letter.dart';

class BoardCell extends StatelessWidget {
  final int row;
  final int col;
  final String displayChar;
  final int? point;
  final bool isTemporary;
  final bool isWordValid;
  final bool myTurn;
  final bool hasAreaRestriction;
  final String restrictedSide;
  final bool hasMine; // Hücrede mayın var mı?
  final bool hasReward; // Hücrede ödül var mı?
  final Function(Map<String, dynamic>)? onAccept;
  final Function()? onTap;

  const BoardCell({
    super.key,
    required this.row,
    required this.col,
    required this.displayChar,
    this.point,
    this.isTemporary = false,
    this.isWordValid = false,
    required this.myTurn,
    this.hasAreaRestriction = false,
    this.restrictedSide = '',
    this.hasMine = false,
    this.hasReward = false,
    this.onAccept,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) {
        // Eğer hücrede zaten bir harf varsa veya oyuncunun turnu değilse kabul etme
        if (!myTurn || displayChar.isNotEmpty) return false;

        // Bölge kısıtlaması kontrolü
        if (hasAreaRestriction) {
          // Sol taraf kısıtlaması
          if (restrictedSide == 'left' && col < 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Sol tarafa harf koyamazsın!"),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }

          // Sağ taraf kısıtlaması
          if (restrictedSide == 'right' && col > 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Sağ tarafa harf koyamazsın!"),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }

        return true; // Doğrulama işlemi dışarıda yapılacak
      },
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        // Hücre rengini belirle
        Color cellColor = _getCellColor();

        return GestureDetector(
          onTap: displayChar.isNotEmpty && isTemporary ? onTap : null,
          child: Stack(
            children: [
              // Temel hücre
              Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: cellColor,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        displayChar,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (displayChar.isNotEmpty && point != null)
                      Positioned(
                        bottom: 2,
                        right: 4,
                        child: Text(
                          point.toString(),
                          style: const TextStyle(fontSize: 8),
                        ),
                      ),
                  ],
                ),
              ),

              // Mayın göstergesi (hücrede harf yoksa)
              if (hasMine && displayChar.isEmpty && myTurn)
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ),

              // Ödül göstergesi (hücrede harf yoksa)
              if (hasReward && displayChar.isEmpty && myTurn)
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amber.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getCellColor() {
    // Eğer hücrede kalıcı bir harf varsa
    if (displayChar.isNotEmpty && !isTemporary) {
      return Colors.amber;
    }

    // Eğer hücrede geçici bir harf varsa
    if (displayChar.isNotEmpty && isTemporary) {
      return isWordValid ? Colors.lightGreen : Colors.red[300]!;
    }

    // Boş hücre için özel hücre rengi
    return SpecialCells.getCellColor(row, col);
  }
}