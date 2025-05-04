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
  final bool isTransformedJoker;
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
    this.isTransformedJoker = false,
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
          if (restrictedSide == 'left' && col < 7) {
            final snackBar = SnackBar(
              content: Row(
                children: [
                  Icon(Icons.block, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Sol taraf kısıtlı! Bu bölgeye harf koyamazsın."),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            );

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            return false;
          }

          // Sağ taraf kısıtlaması
          if (restrictedSide == 'right' && col > 7) {
            final snackBar = SnackBar(
              content: Row(
                children: [
                  Icon(Icons.block, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Sağ taraf kısıtlı! Bu bölgeye harf koyamazsın."),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            );

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            return false;
          }
        }

        return true; // Doğrulama işlemi dışarıda yapılacak
      },
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        // Hücre rengini belirle
        Color cellColor = _getCellColor();
        bool isSpecialCell = SpecialCells.isDoubleLetterScore(row, col) ||
            SpecialCells.isTripleLetterScore(row, col) ||
            SpecialCells.isDoubleWordScore(row, col) ||
            SpecialCells.isTripleWordScore(row, col) ||
            SpecialCells.isCenter(row, col);


        return GestureDetector(
          onTap: displayChar.isNotEmpty && isTemporary ? onTap : null,
          child: Stack(
            children: [
              // Hücre arka planı
              Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isTransformedJoker ? Colors.purple[100] : cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isTransformedJoker
                        ? Colors.purple
                        : isSpecialCell
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                    width: isTransformedJoker ? 2 : 0.8,
                  ),
                  boxShadow: displayChar.isNotEmpty
                      ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    )
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    // Merkezi harf
                    if (displayChar.isNotEmpty)
                      Center(
                        child: Text(
                          displayChar,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,  // Biraz daha büyük
                            color: isTransformedJoker ? Colors.purple[900] : Colors.black87, // Hafif ton
                          ),
                        ),
                      ),

                    // Puan göstergesi
                    if (displayChar.isNotEmpty && point != null)
                      Positioned(
                        bottom: 2,
                        right: 4,
                        child: Text(
                          point.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                    // JOKER göstergesi (dönüştürülmüş JOKER için)
                    if (isTransformedJoker)
                      Positioned(
                        top: 2,
                        right: 4,
                        child: Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.purple,
                        ),
                      ),

                    // Özel hücre göstergeleri
                    if (displayChar.isEmpty && isSpecialCell)
                      Center(
                        child: Text(
                          _getSpecialCellText(row, col),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSpecialCellTextColor(row, col),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Mayın göstergesi (hücrede harf yoksa) - animasyonlu
              if (hasMine && displayChar.isEmpty && myTurn)
                Positioned.fill(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Center(
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.withOpacity(0.8),
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Ödül göstergesi (hücrede harf yoksa) - animasyonlu
              if (hasReward && displayChar.isEmpty && myTurn)
                Positioned.fill(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Center(
                          child: Icon(
                            Icons.star_rounded,
                            color: Colors.amber.withOpacity(0.8),
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Get the appropriate icon for special cells
  String _getSpecialCellText(int row, int col) {
    if (SpecialCells.isCenter(row, col)) {
      return "★";
    } else if (SpecialCells.isDoubleLetterScore(row, col)) {
      return "H×2";
    } else if (SpecialCells.isTripleLetterScore(row, col)) {
      return "H×3";
    } else if (SpecialCells.isDoubleWordScore(row, col)) {
      return "K×2";
    } else if (SpecialCells.isTripleWordScore(row, col)) {
      return "K×3";
    }
    return "";
  }

// Özel hücre metin rengi
  Color _getSpecialCellTextColor(int row, int col) {
    if (SpecialCells.isCenter(row, col)) {
      return Colors.purple[700]!;
    } else if (SpecialCells.isDoubleLetterScore(row, col) ||
        SpecialCells.isTripleLetterScore(row, col)) {
      return Colors.blue[700]!;
    } else if (SpecialCells.isDoubleWordScore(row, col) ||
        SpecialCells.isTripleWordScore(row, col)) {
      return Colors.red[700]!;
    }
    return Colors.grey;
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