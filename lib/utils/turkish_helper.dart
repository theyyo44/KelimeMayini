// utils/turkish_helper.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class TurkishHelper {
  static Set<String> _validWords = {};
  static bool _initialized = false;

  /// Türkçe kelime listesini yükler
  static Future<void> loadWordList() async {
    if (_initialized) return;

    try {
      // Türkçe kelime listesini assets'ten yükle
      final String data = await rootBundle.loadString('assets/turkish_words.txt');
      final List<String> words = LineSplitter.split(data).toList();

      _validWords = Set<String>.from(words.map((w) => turkishLowerCase(w)));
      _initialized = true;
    } catch (e) {
      print('Kelime listesi yüklenirken hata: $e');
      _initialized = false;
    }
  }

  /// Kelimenin geçerli bir Türkçe kelime olup olmadığını kontrol eder
  static bool isValidWord(String word) {
    if (!_initialized) {
      print('Hata: Kelime listesi henüz yüklenmemiş');
      return false;
    }

    return _validWords.contains(turkishLowerCase(word));
  }

  /// Türkçe karakter dönüşümlerini dikkate alarak küçük harfe çevirir
  static String turkishLowerCase(String text) {
    final Map<String, String> turkishChars = {
      'I': 'ı', // Büyük I -> küçük ı
      'İ': 'i', // Büyük İ -> küçük i
      'Ç': 'ç',
      'Ğ': 'ğ',
      'Ö': 'ö',
      'Ş': 'ş',
      'Ü': 'ü',
    };

    String result = text;
    turkishChars.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    // Geriye kalan karakterler için normal toLowerCase kullan
    return result.toLowerCase();
  }

  /// Türkçe karakter dönüşümlerini dikkate alarak büyük harfe çevirir
  static String turkishUpperCase(String text) {
    final Map<String, String> turkishChars = {
      'i': 'İ', // küçük i -> Büyük İ
      'ı': 'I', // küçük ı -> Büyük I
      'ç': 'Ç',
      'ğ': 'Ğ',
      'ö': 'Ö',
      'ş': 'Ş',
      'ü': 'Ü',
    };

    String result = text;
    turkishChars.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    // Geriye kalan karakterler için normal toUpperCase kullan
    return result.toUpperCase();
  }

  /// Test amaçlı rastgele geçerli Türkçe kelime oluşturur
  static String getRandomValidWord() {
    if (!_initialized || _validWords.isEmpty) {
      return "ÖRNEK";
    }

    final random = Random();
    final wordsList = _validWords.toList();
    final randomIndex = random.nextInt(wordsList.length);
    return turkishUpperCase(wordsList[randomIndex]);
  }
}