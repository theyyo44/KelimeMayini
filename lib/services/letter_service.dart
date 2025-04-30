// services/letter_service.dart
import 'dart:math';
import '../models/letter.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

class LetterService {
  final FirebaseService _firebaseService;
  List<Letter> _letterPool = [];
  int _nextLetterId = 0;

  LetterService(this._firebaseService);

  /// Harf havuzunu başlatır
  void initializeLetterPool() {
    _letterPool = [];

    // LETTER_POOL sabitinden harfleri oluştur
    for (var letterInfo in LETTER_POOL) {
      final char = letterInfo['char'] as String;
      final count = letterInfo['count'] as int;
      final point = letterInfo['point'] as int;

      for (int i = 0; i < count; i++) {
        _letterPool.add(Letter(
          char: char,
          point: point,
          id: 0, // Havuzdaki harflerin ID'si yok
          isJoker: char == 'JOKER',
        ));
      }
    }

    // Havuzu karıştır
    _letterPool.shuffle(Random());

    print("Harf havuzu başlatıldı. Toplam harf sayısı: ${_letterPool.length}");
  }

  /// Oyun başlangıcında tüm oyunculara harf dağıtır (Orijinal kodla uyumlu)
  Future<void> initializeGameLetters(String gameId) async {
    // Önce harf havuzunu başlat
    initializeLetterPool();

    // Oyuncuları al
    final gameState = await _firebaseService.loadGameState(gameId);
    final players = gameState.players;

    if (players.length < 2) {
      print("Hata: Oyuncu sayısı yetersiz");
      return;
    }

    final player1 = players[0];
    final player2 = players[1];

    // İlk 14 harfi dağıt
    final lettersForPlayer1 = <Letter>[];
    final lettersForPlayer2 = <Letter>[];

    // İlk 7 harf 1. oyuncuya
    for (int i = 0; i < 7 && i < _letterPool.length; i++) {
      lettersForPlayer1.add(Letter(
        char: _letterPool[i].char,
        point: _letterPool[i].point,
        id: _nextLetterId++,
        isJoker: _letterPool[i].isJoker,
      ));
    }

    // Sonraki 7 harf 2. oyuncuya
    for (int i = 7; i < 14 && i < _letterPool.length; i++) {
      lettersForPlayer2.add(Letter(
        char: _letterPool[i].char,
        point: _letterPool[i].point,
        id: _nextLetterId++,
        isJoker: _letterPool[i].isJoker,
      ));
    }

    // Kalan harfler havuzda kalacak
    if (_letterPool.length >= 14) {
      _letterPool = _letterPool.sublist(14);
    } else {
      _letterPool = [];
    }

    print("Harf dağıtımı sonrası kalan harf sayısı: ${_letterPool.length}");

    // Firebase'e kaydet
    await _firebaseService.updateUserLetters(gameId, player1, lettersForPlayer1);
    await _firebaseService.updateUserLetters(gameId, player2, lettersForPlayer2);
    await _firebaseService.updateLetterPool(gameId, _letterPool);
  }

  /// Tek bir oyuncu için ilk harfleri dağıtır
  Future<List<Letter>> distributeInitialLetters(String gameId, String userId) async {
    if (_letterPool.isEmpty) {
      // Havuzdan bilgi almamız gerekiyor
      final gameState = await _firebaseService.loadGameState(gameId);
      _letterPool = gameState.letterPool;
      print("Havuz boş, Firebase'den alındı. Mevcut harf sayısı: ${_letterPool.length}");
    }

    // İlk 7 harfi al (havuzda daha az varsa mevcut sayıyı)
    final count = min(MAX_LETTERS_PER_PLAYER, _letterPool.length);
    final userLetters = <Letter>[];

    for (int i = 0; i < count; i++) {
      if (_letterPool.isEmpty) break;

      final letter = _letterPool.removeAt(0);
      userLetters.add(Letter(
        char: letter.char,
        point: letter.point,
        id: _nextLetterId++,
        isJoker: letter.isJoker,
      ));
    }

    print("Harfler dağıtıldı. Kalan harf sayısı: ${_letterPool.length}");

    // Firebase'e kaydet
    await _firebaseService.updateUserLetters(gameId, userId, userLetters);
    await _firebaseService.updateLetterPool(gameId, _letterPool);

    return userLetters;
  }

  /// Yeni harfler çeker
  Future<List<Letter>> drawNewLetters(String gameId, String userId, List<Letter> currentLetters, int count) async {
    // Havuz boşsa güncel harf havuzunu Firebase'den al
    if (_letterPool.isEmpty || _letterPool.length < count) {
      final gameState = await _firebaseService.loadGameState(gameId);
      _letterPool = gameState.letterPool;
      print("Havuz yetersiz, Firebase'den alındı. Yeni harf sayısı: ${_letterPool.length}");
    }

    if (_letterPool.isEmpty) return currentLetters;

    final drawCount = min(count, _letterPool.length);
    if (drawCount <= 0) return currentLetters;

    final newLetters = <Letter>[];
    for (int i = 0; i < drawCount; i++) {
      if (_letterPool.isEmpty) break;

      final letter = _letterPool.removeAt(0); // Havuzdan ilk harfi çıkar
      newLetters.add(Letter(
        char: letter.char,
        point: letter.point,
        id: _nextLetterId++,
        isJoker: letter.isJoker,
      ));
    }

    final updatedLetters = [...currentLetters, ...newLetters];

    print("Yeni harf çekimi sonrası kalan harf sayısı: ${_letterPool.length}");

    // Firebase'e kaydet
    await _firebaseService.updateUserLetters(gameId, userId, updatedLetters);
    await _firebaseService.updateLetterPool(gameId, _letterPool);

    return updatedLetters;
  }

  /// Harfleri sıfırlar (harf kaybı mayını için)
  Future<List<Letter>> resetLetters(String gameId, String userId, List<Letter> currentLetters) async {
    // Firebase'den güncel harf havuzunu al
    final gameState = await _firebaseService.loadGameState(gameId);
    _letterPool = gameState.letterPool;

    // Mevcut harfleri havuza geri koy
    for (var letter in currentLetters) {
      _letterPool.add(Letter(
        char: letter.char,
        point: letter.point,
        id: 0,
        isJoker: letter.isJoker,
      ));
    }

    // Havuzu karıştır
    _letterPool.shuffle(Random());

    print("Harfler sıfırlandı, havuza geri eklendi. Havuz boyutu: ${_letterPool.length}");

    // Yeni 7 harf al
    return await distributeInitialLetters(gameId, userId);
  }

  /// Kullanılan harfleri tahtaya koyar ve kullanıcının harflerinden çıkarır
  Future<List<Letter>> placeLettersOnBoard(
      String gameId,
      String userId,
      List<Letter> currentLetters,
      Map<String, Letter> placedLetters,
      ) async {
    final usedLetterIds = placedLetters.values.map((l) => l.id).toList();
    final remainingLetters = currentLetters.where((l) => !usedLetterIds.contains(l.id)).toList();

    // Firebase'e kaydet
    await _firebaseService.updateUserLetters(gameId, userId, remainingLetters);

    return remainingLetters;
  }

  /// Kalan harf sayısını döndürür
  int getRemainingLettersCount() {
    return _letterPool.length;
  }

  /// Next letter ID'yi ayarlar
  void setNextLetterId(int id) {
    _nextLetterId = id;
  }

  /// Harf havuzunu ayarlar
  void setLetterPool(List<Letter> letterPool) {
    _letterPool = letterPool;
    print("Harf havuzu güncellendi. Yeni boyut: ${_letterPool.length}");
  }

  /// Harf havuzunu döndürür
  List<Letter> getLetterPool() {
    return _letterPool;
  }

  /// Harf ID'si için uygun bir harf döndürür
  Letter? getLetterById(List<Letter> letters, int id) {
    try {
      return letters.firstWhere((letter) => letter.id == id);
    } catch (e) {
      return null;
    }
  }
}