// utils/constants.dart
import 'package:flutter/material.dart';

/// Oyun tahtası boyutları
const int BOARD_SIZE = 15;

/// Oyuncu başına maksimum harf sayısı
const int MAX_LETTERS_PER_PLAYER = 7;

/// Peş peşe pas sayısı limiti
const int MAX_CONSECUTIVE_PASSES = 4;

/// Türkçe harfler ve puanları
final List<Map<String, dynamic>> LETTER_POOL = [
  {"char": "A", "count": 12, "point": 1},
  {"char": "B", "count": 2, "point": 3},
  {"char": "C", "count": 2, "point": 4},
  {"char": "Ç", "count": 2, "point": 4},
  {"char": "D", "count": 2, "point": 3},
  {"char": "E", "count": 8, "point": 1},
  {"char": "F", "count": 1, "point": 7},
  {"char": "G", "count": 1, "point": 5},
  {"char": "Ğ", "count": 1, "point": 8},
  {"char": "H", "count": 1, "point": 5},
  {"char": "I", "count": 4, "point": 2},
  {"char": "İ", "count": 7, "point": 1},
  {"char": "J", "count": 1, "point": 10},
  {"char": "K", "count": 7, "point": 1},
  {"char": "L", "count": 7, "point": 1},
  {"char": "M", "count": 4, "point": 2},
  {"char": "N", "count": 5, "point": 1},
  {"char": "O", "count": 3, "point": 2},
  {"char": "Ö", "count": 1, "point": 7},
  {"char": "P", "count": 1, "point": 5},
  {"char": "R", "count": 6, "point": 1},
  {"char": "S", "count": 3, "point": 2},
  {"char": "Ş", "count": 2, "point": 4},
  {"char": "T", "count": 5, "point": 1},
  {"char": "U", "count": 3, "point": 2},
  {"char": "Ü", "count": 2, "point": 3},
  {"char": "V", "count": 1, "point": 7},
  {"char": "Y", "count": 2, "point": 3},
  {"char": "Z", "count": 2, "point": 4},
  {"char": "JOKER", "count": 2, "point": 0},
];

/// Mayın tipleri ve sayıları
final List<Map<String, dynamic>> MINE_TYPES = [
  {'type': 'pointDivision', 'count': 5}, // Puan Bölünmesi
  {'type': 'pointTransfer', 'count': 4}, // Puan Transferi
  {'type': 'letterLoss', 'count': 3},    // Harf Kaybı
  {'type': 'bonusBlock', 'count': 2},    // Ekstra Hamle Engeli
  {'type': 'wordCancel', 'count': 2},    // Kelime İptali
];

/// Ödül tipleri ve sayıları
final List<Map<String, dynamic>> REWARD_TYPES = [
  {'type': 'areaRestriction', 'count': 2}, // Bölge Yasağı
  {'type': 'letterRestriction', 'count': 3}, // Harf Yasağı
  {'type': 'extraMove', 'count': 2},       // Ekstra Hamle Jokeri
];

/// Özel hücre tanımları
class SpecialCells {
  /// İki kat harf puanı (DLS) hücreleri
  static bool isDoubleLetterScore(int row, int col) {
    return (row == 3 && (col == 0 || col == 7 || col == 14)) ||
        (row == 7 && (col == 3 || col == 11)) ||
        (row == 11 && (col == 0 || col == 7 || col == 14));
  }

  /// Üç kat harf puanı (TLS) hücreleri
  static bool isTripleLetterScore(int row, int col) {
    return (row == 1 && (col == 5 || col == 9)) ||
        (row == 5 && (col == 1 || col == 5 || col == 9 || col == 13)) ||
        (row == 9 && (col == 1 || col == 5 || col == 9 || col == 13)) ||
        (row == 13 && (col == 5 || col == 9));
  }

  /// İki kat kelime puanı (DWS) hücreleri
  static bool isDoubleWordScore(int row, int col) {
    return (row == 1 && (col == 1 || col == 13)) ||
        (row == 2 && (col == 2 || col == 12)) ||
        (row == 3 && (col == 3 || col == 11)) ||
        (row == 4 && (col == 4 || col == 10)) ||
        (row == 10 && (col == 4 || col == 10)) ||
        (row == 11 && (col == 3 || col == 11)) ||
        (row == 12 && (col == 2 || col == 12)) ||
        (row == 13 && (col == 1 || col == 13));
  }

  /// Üç kat kelime puanı (TWS) hücreleri
  static bool isTripleWordScore(int row, int col) {
    return (row == 0 && (col == 0 || col == 7 || col == 14)) ||
        (row == 7 && (col == 0 || col == 14)) ||
        (row == 14 && (col == 0 || col == 7 || col == 14));
  }

  /// Merkez hücresi
  static bool isCenter(int row, int col) {
    return row == 7 && col == 7;
  }

  /// Hücre renklerini döndüren fonksiyon
  static Color getCellColor(int row, int col) {
    if (isCenter(row, col)) {
      return Colors.purple[100]!;
    } else if (isDoubleLetterScore(row, col)) {
      return Colors.blue[100]!;
    } else if (isTripleLetterScore(row, col)) {
      return Colors.blue[300]!;
    } else if (isDoubleWordScore(row, col)) {
      return Colors.red[100]!;
    } else if (isTripleWordScore(row, col)) {
      return Colors.red[300]!;
    } else {
      return Colors.white;
    }
  }

  /// Hücre açıklamasını döndüren fonksiyon
  static String getCellDescription(int row, int col) {
    if (isCenter(row, col)) {
      return "Başlangıç hücresi";
    } else if (isDoubleLetterScore(row, col)) {
      return "Harf puanı 2 kat";
    } else if (isTripleLetterScore(row, col)) {
      return "Harf puanı 3 kat";
    } else if (isDoubleWordScore(row, col)) {
      return "Kelime puanı 2 kat";
    } else if (isTripleWordScore(row, col)) {
      return "Kelime puanı 3 kat";
    } else {
      return "";
    }
  }
}

/// Oyun stilleri
class GameStyles {
  static const Color primaryColor = Color(0xFF2C2077);
  static const Color secondaryColor = Color(0xFF3E2C8F);
  static const Color accentColor = Colors.amber;

  static const TextStyle headingStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle scoreStyle = TextStyle(
    color: accentColor,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle letterStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const TextStyle letterPointStyle = TextStyle(
    fontSize: 10,
  );

  static ButtonStyle actionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}