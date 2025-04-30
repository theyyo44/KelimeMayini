// utils/validators.dart
import '../models/game_state.dart';
import 'turkish_helper.dart';
import 'constants.dart';

/// Oyun doğrulama için kullanılan sınıf
class GameValidator {

  /// Tahtaya harf yerleştirme kurallarını kontrol eder
  static bool isValidPlacement(
      List<List<String>> board,
      Map<String, Map<String, dynamic>> placedLetters,
      Map<String, Map<String, dynamic>> tempPlacedLetters,
      {
        bool hasAreaRestriction = false,
        String restrictedSide = '',
      }
      ) {
    // Kontrol 1: En az bir harf yerleştirilmiş olmalı
    if (tempPlacedLetters.isEmpty) return false;

    // Kontrol 2: İlk hamle için özel kontroller
    bool isFirstMove = board.every((row) => row.every((cell) => cell.isEmpty));
    if (isFirstMove) {
      // Sadece harflerin yatay veya dikey bir çizgide olmasını kontrol edelim
      bool isHorizontal = true;
      bool isVertical = true;
      int? commonRow, commonCol;

      List<String> positions = tempPlacedLetters.keys.toList();
      if (positions.length > 1) {
        List<int> firstParts = positions[0].split('-').map(int.parse).toList();
        commonRow = firstParts[0];
        commonCol = firstParts[1];

        for (int i = 1; i < positions.length; i++) {
          List<int> parts = positions[i].split('-').map(int.parse).toList();
          if (parts[0] != commonRow) isHorizontal = false;
          if (parts[1] != commonCol) isVertical = false;
        }

        if (!isHorizontal && !isVertical) return false;
      }

      return true;
    }

    // Kontrol 3: Yerleştirilen harfler tek doğrultuda olmalı
    if (tempPlacedLetters.length > 1) {
      bool isHorizontal = true;
      bool isVertical = true;

      List<String> positions = tempPlacedLetters.keys.toList();
      List<List<int>> coords = positions.map((p) => p.split('-').map(int.parse).toList()).toList();

      int firstRow = coords[0][0];
      int firstCol = coords[0][1];

      // Tüm harflerin aynı satır veya sütunda olup olmadığını kontrol et
      for (int i = 1; i < coords.length; i++) {
        if (coords[i][0] != firstRow) isHorizontal = false;
        if (coords[i][1] != firstCol) isVertical = false;
      }

      // Ne yatay ne dikey ise geçersiz yerleştirme
      if (!isHorizontal && !isVertical) return false;
    }

    // Kontrol 4: En az bir mevcut harfe bitişik olmalı (ilk hamle değilse)
    bool touchesExistingLetter = false;

    for (var position in tempPlacedLetters.keys) {
      final parts = position.split('-');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);

      // Bölge kısıtlaması kontrolü
      if (hasAreaRestriction) {
        if (restrictedSide == 'left' && col < 7) {
          return false; // Sol taraf kısıtlı
        } else if (restrictedSide == 'right' && col > 7) {
          return false; // Sağ taraf kısıtlı
        }
      }

      // Yukarı, aşağı, sol, sağ hücreleri kontrol et
      final directions = [
        [row - 1, col], // yukarı
        [row + 1, col], // aşağı
        [row, col - 1], // sol
        [row, col + 1], // sağ
      ];

      for (var dir in directions) {
        int r = dir[0];
        int c = dir[1];

        if (r >= 0 && r < BOARD_SIZE && c >= 0 && c < BOARD_SIZE) {
          // Tahtada yerleşik bir harfe dokunuyor mu?
          if (board[r][c].isNotEmpty) {
            touchesExistingLetter = true;
            break;
          }
        }
      }

      if (touchesExistingLetter) break;
    }

    if (!touchesExistingLetter) return false;

    // Kontrol 5: Yerleştirilen harfler ya yatay ya da dikey bir çizgide olmalı
    bool isHorizontal = true;
    bool isVertical = true;
    int? commonRow, commonCol;

    List<String> positions = tempPlacedLetters.keys.toList();
    if (positions.length > 1) {
      // İlk iki konum arasında yön belirle
      List<int> parts1 = positions[0].split('-').map(int.parse).toList();
      List<int> parts2 = positions[1].split('-').map(int.parse).toList();

      if (parts1[0] == parts2[0]) {
        // Yatay yerleştirme (aynı satır)
        isVertical = false;
        commonRow = parts1[0];
      } else if (parts1[1] == parts2[1]) {
        // Dikey yerleştirme (aynı sütun)
        isHorizontal = false;
        commonCol = parts1[1];
      } else {
        // Ne yatay ne dikey
        return false;
      }

      // Diğer tüm konumlar için yönü doğrula
      for (int i = 2; i < positions.length; i++) {
        List<int> parts = positions[i].split('-').map(int.parse).toList();

        if (isHorizontal && parts[0] != commonRow) return false;
        if (isVertical && parts[1] != commonCol) return false;
      }
    }

    // Kontrol 6: Yerleştirilen harfler birbirine bitişik olmalı (boşluk olmamalı)
    if (positions.length > 1) {
      // Pozisyonları sırala
      if (isHorizontal && commonRow != null) {
        // Sütun numaralarına göre sırala
        positions.sort((a, b) {
          int colA = int.parse(a.split('-')[1]);
          int colB = int.parse(b.split('-')[1]);
          return colA.compareTo(colB);
        });

        // Ardışık olduğunu kontrol et
        for (int i = 1; i < positions.length; i++) {
          int prevCol = int.parse(positions[i-1].split('-')[1]);
          int currCol = int.parse(positions[i].split('-')[1]);

          // Aradaki boşlukları kontrol et
          for (int col = prevCol + 1; col < currCol; col++) {
            // Boşluk tahtadaki bir harfle doldurulmuş mu?
            if (board[commonRow][col].isEmpty) {
              return false;
            }
          }
        }
      } else if (isVertical && commonCol != null) {
        // Satır numaralarına göre sırala
        positions.sort((a, b) {
          int rowA = int.parse(a.split('-')[0]);
          int rowB = int.parse(b.split('-')[0]);
          return rowA.compareTo(rowB);
        });

        // Ardışık olduğunu kontrol et
        for (int i = 1; i < positions.length; i++) {
          int prevRow = int.parse(positions[i-1].split('-')[0]);
          int currRow = int.parse(positions[i].split('-')[0]);

          // Aradaki boşlukları kontrol et
          for (int row = prevRow + 1; row < currRow; row++) {
            // Boşluk tahtadaki bir harfle doldurulmuş mu?
            if (board[row][commonCol].isEmpty) {
              return false;
            }
          }
        }
      }
    }

    return true;
  }

  /// İlk hamle için özel kontrol
  static bool isValidFirstMove(Map<String, Map<String, dynamic>> tempPlacedLetters) {
    // İlk hamle merkez hücreden (7,7) geçmeli
    return tempPlacedLetters.containsKey('7-7');
  }

  /// Yerleştirilen harflerden kelime oluşturma ve doğrulama
  static Map<String, dynamic> getWordInfo(
      List<List<String>> board,
      Map<String, Map<String, dynamic>> tempPlacedLetters
      ) {
    if (tempPlacedLetters.isEmpty) {
      return {
        'word': '',
        'isValid': false,
        'score': 0,
      };
    }

    // Ana kelimeyi bulma
    List<String> positions = tempPlacedLetters.keys.toList();

    // Tüm harfler aynı satırda mı yoksa aynı sütunda mı kontrol et
    bool allSameRow = true;
    bool allSameCol = true;
    int? firstRow, firstCol;

    if (positions.isNotEmpty) {
      List<int> parts = positions[0].split('-').map(int.parse).toList();
      firstRow = parts[0];
      firstCol = parts[1];

      for (int i = 1; i < positions.length; i++) {
        List<int> currentParts = positions[i].split('-').map(int.parse).toList();
        if (currentParts[0] != firstRow) allSameRow = false;
        if (currentParts[1] != firstCol) allSameCol = false;
      }
    }

    bool isHorizontal = allSameRow && !allSameCol;
    bool isVertical = !allSameRow && allSameCol;

    // Tek bir harf yerleştirilmiş olabilir, yönü belirlemek için komşularına bakmalıyız
    if (positions.length == 1 && firstRow != null && firstCol != null) {
      bool hasHorizontalNeighbor = (firstCol > 0 && board[firstRow][firstCol - 1].isNotEmpty) ||
          (firstCol < 14 && board[firstRow][firstCol + 1].isNotEmpty);
      bool hasVerticalNeighbor = (firstRow > 0 && board[firstRow - 1][firstCol].isNotEmpty) ||
          (firstRow < 14 && board[firstRow + 1][firstCol].isNotEmpty);

      if (hasHorizontalNeighbor && !hasVerticalNeighbor) {
        isHorizontal = true;
        isVertical = false;
      } else if (!hasHorizontalNeighbor && hasVerticalNeighbor) {
        isHorizontal = false;
        isVertical = true;
      } else {
        // Varsayılan olarak yatay diyelim
        isHorizontal = true;
        isVertical = false;
      }
    }

    // Ana kelimeyi oluştur ve kontrol et
    String mainWord = "";
    int totalScore = 0;
    bool allWordsValid = true;
    List<Map<String, dynamic>> allWords = [];

    // Ana kelimeyi kontrol et
    if (isHorizontal && firstRow != null) {
      // Yatay kelime için, en sol noktayı bul
      int minCol = firstCol!;
      while (minCol > 0 && (board[firstRow][minCol - 1].isNotEmpty || tempPlacedLetters.containsKey('$firstRow-${minCol - 1}'))) {
        minCol--;
      }

      // Kelimeyi oluştur
      String word = "";
      for (int col = minCol; col < BOARD_SIZE; col++) {
        String letter = "";
        if (tempPlacedLetters.containsKey('$firstRow-$col')) {
          letter = tempPlacedLetters['$firstRow-$col']!['char'];
        } else if (board[firstRow][col].isNotEmpty) {
          letter = board[firstRow][col];
        } else {
          break; // Kelime sona erdi
        }
        word += letter;
      }

      if (word.length > 1) {
        mainWord = word;
        bool wordValid = TurkishHelper.isValidWord(word);
        int wordScore = calculateWordScore(true, firstRow, minCol, word.length, board, tempPlacedLetters);
        totalScore += wordScore;

        allWords.add({
          'word': word,
          'isValid': wordValid,
          'score': wordScore,
          'isMain': true
        });

        if (!wordValid) allWordsValid = false;
      }

      // Dikey yan kelimeleri kontrol et
      for (var position in tempPlacedLetters.keys) {
        List<int> parts = position.split('-').map(int.parse).toList();
        int row = parts[0];
        int col = parts[1];

        // Sadece yatay ana doğrultudaki harfler için çapraz kontrol yap
        if (row == firstRow) {
          String crossWord = _getVerticalWordAt(row, col, board, tempPlacedLetters);

          if (crossWord.length > 1) {
            bool crossWordValid = TurkishHelper.isValidWord(crossWord);
            int crossWordScore = calculateWordScore(false, _getVerticalWordStartRow(row, col, board, tempPlacedLetters), col, crossWord.length, board, tempPlacedLetters);
            totalScore += crossWordScore;

            allWords.add({
              'word': crossWord,
              'isValid': crossWordValid,
              'score': crossWordScore,
              'isMain': false
            });

            if (!crossWordValid) allWordsValid = false;
          }
        }
      }
    } else if (isVertical && firstCol != null) {
      // Dikey kelime için, en üst noktayı bul
      int minRow = firstRow!;
      while (minRow > 0 && (board[minRow - 1][firstCol].isNotEmpty || tempPlacedLetters.containsKey('${minRow - 1}-$firstCol'))) {
        minRow--;
      }

      // Kelimeyi oluştur
      String word = "";
      for (int row = minRow; row < BOARD_SIZE; row++) {
        String letter = "";
        if (tempPlacedLetters.containsKey('$row-$firstCol')) {
          letter = tempPlacedLetters['$row-$firstCol']!['char'];
        } else if (board[row][firstCol].isNotEmpty) {
          letter = board[row][firstCol];
        } else {
          break; // Kelime sona erdi
        }
        word += letter;
      }

      if (word.length > 1) {
        mainWord = word;
        bool wordValid = TurkishHelper.isValidWord(word);
        int wordScore = calculateWordScore(false, minRow, firstCol, word.length, board, tempPlacedLetters);
        totalScore += wordScore;

        allWords.add({
          'word': word,
          'isValid': wordValid,
          'score': wordScore,
          'isMain': true
        });

        if (!wordValid) allWordsValid = false;
      }

      // Yatay yan kelimeleri kontrol et
      for (var position in tempPlacedLetters.keys) {
        List<int> parts = position.split('-').map(int.parse).toList();
        int row = parts[0];
        int col = parts[1];

        // Sadece dikey ana doğrultudaki harfler için çapraz kontrol yap
        if (col == firstCol) {
          String crossWord = _getHorizontalWordAt(row, col, board, tempPlacedLetters);

          if (crossWord.length > 1) {
            bool crossWordValid = TurkishHelper.isValidWord(crossWord);
            int crossWordScore = calculateWordScore(true, row, _getHorizontalWordStartCol(row, col, board, tempPlacedLetters), crossWord.length, board, tempPlacedLetters);
            totalScore += crossWordScore;

            allWords.add({
              'word': crossWord,
              'isValid': crossWordValid,
              'score': crossWordScore,
              'isMain': false
            });

            if (!crossWordValid) allWordsValid = false;
          }
        }
      }
    }

    return {
      'word': mainWord,
      'isValid': allWordsValid && mainWord.length > 1,
      'score': totalScore,
      'allWords': allWords,
    };
  }

  /// Belirli bir konumdan (row, col) dikey kelimeyi oluşturur
  static String _getVerticalWordAt(int row, int col, List<List<String>> board, Map<String, Map<String, dynamic>> tempPlacedLetters) {
    // Kelimenin başlangıç satırını bul
    int startRow = row;
    while (startRow > 0 && (board[startRow - 1][col].isNotEmpty || tempPlacedLetters.containsKey('${startRow - 1}-$col'))) {
      startRow--;
    }

    // Kelimeyi oluştur
    String word = "";
    for (int r = startRow; r < BOARD_SIZE; r++) {
      String letter = "";
      if (tempPlacedLetters.containsKey('$r-$col')) {
        letter = tempPlacedLetters['$r-$col']!['char'];
      } else if (board[r][col].isNotEmpty) {
        letter = board[r][col];
      } else {
        break; // Kelime sona erdi
      }
      word += letter;
    }

    return word;
  }

  /// Dikey kelimenin başlangıç satırını bulur
  static int _getVerticalWordStartRow(int row, int col, List<List<String>> board, Map<String, Map<String, dynamic>> tempPlacedLetters) {
    int startRow = row;
    while (startRow > 0 && (board[startRow - 1][col].isNotEmpty || tempPlacedLetters.containsKey('${startRow - 1}-$col'))) {
      startRow--;
    }
    return startRow;
  }

  /// Belirli bir konumdan (row, col) yatay kelimeyi oluşturur
  static String _getHorizontalWordAt(int row, int col, List<List<String>> board, Map<String, Map<String, dynamic>> tempPlacedLetters) {
    // Kelimenin başlangıç sütununu bul
    int startCol = col;
    while (startCol > 0 && (board[row][startCol - 1].isNotEmpty || tempPlacedLetters.containsKey('$row-${startCol - 1}'))) {
      startCol--;
    }

    // Kelimeyi oluştur
    String word = "";
    for (int c = startCol; c < BOARD_SIZE; c++) {
      String letter = "";
      if (tempPlacedLetters.containsKey('$row-$c')) {
        letter = tempPlacedLetters['$row-$c']!['char'];
      } else if (board[row][c].isNotEmpty) {
        letter = board[row][c];
      } else {
        break; // Kelime sona erdi
      }
      word += letter;
    }

    return word;
  }

  /// Yatay kelimenin başlangıç sütununu bulur
  static int _getHorizontalWordStartCol(int row, int col, List<List<String>> board, Map<String, Map<String, dynamic>> tempPlacedLetters) {
    int startCol = col;
    while (startCol > 0 && (board[row][startCol - 1].isNotEmpty || tempPlacedLetters.containsKey('$row-${startCol - 1}'))) {
      startCol--;
    }
    return startCol;
  }

  /// Kelime puanını hesapla
  static int calculateWordScore(
      bool isHorizontal,
      int startRow,
      int startCol,
      int length,
      List<List<String>> board,
      Map<String, Map<String, dynamic>> tempPlacedLetters
      ) {
    int score = 0;
    int wordMultiplier = 1;

    for (int i = 0; i < length; i++) {
      int row = isHorizontal ? startRow : startRow + i;
      int col = isHorizontal ? startCol + i : startCol;

      // Sınırları kontrol et
      if (row >= BOARD_SIZE || col >= BOARD_SIZE) break;

      // Harfin puanını al
      int letterPoint = 0;
      String posKey = '$row-$col';

      if (tempPlacedLetters.containsKey(posKey)) {
        letterPoint = tempPlacedLetters[posKey]!['point'] as int;
      } else if (board[row][col].isNotEmpty) {
        // Tahtadaki harfin puanını bulmak için LETTER_POOL'dan arama yapabilirsiniz
        String letter = board[row][col];
        var letterInfo = LETTER_POOL.firstWhere((l) => l['char'] == letter, orElse: () => {"point": 1});
        letterPoint = letterInfo['point'] as int;
      }

      int letterMultiplier = 1;

      // Özel hücreler için çarpanları uygula (sadece yeni yerleştirilen harfler için)
      if (tempPlacedLetters.containsKey(posKey)) {
        // Harfin 2 katı
        if (SpecialCells.isDoubleLetterScore(row, col)) {
          letterMultiplier = 2;
        }
        // Harfin 3 katı
        else if (SpecialCells.isTripleLetterScore(row, col)) {
          letterMultiplier = 3;
        }
        // Kelimenin 2 katı
        else if (SpecialCells.isDoubleWordScore(row, col)) {
          wordMultiplier *= 2;
        }
        // Kelimenin 3 katı
        else if (SpecialCells.isTripleWordScore(row, col)) {
          wordMultiplier *= 3;
        }
      }

      score += letterPoint * letterMultiplier;
    }

    // Kelime çarpanını uygula
    return score * wordMultiplier;
  }
}