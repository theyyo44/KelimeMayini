// services/game_logic_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../models/mine.dart';
import '../models/reward.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'firebase_service.dart';
import 'letter_service.dart';

class GameLogicService {
  final FirebaseService _firebaseService;
  final LetterService _letterService;

  GameLogicService(this._firebaseService, this._letterService);

  /// Kelime yerleştirmeyi doğrular ve skoru hesaplar
  Map<String, dynamic> validatePlacement({
    required List<List<String>> board,
    required Map<String, Map<String, dynamic>> placedLetters,
    required Map<String, Map<String, dynamic>> tempPlacedLetters,
    bool hasAreaRestriction = false,
    String restrictedSide = '',
  }) {
    // İlk hamle kontrolü
    bool isFirstMove = board.every((row) => row.every((cell) => cell.isEmpty));

    // Yerleştirmeyi doğrula
    bool isValid = GameValidator.isValidPlacement(
      board,
      placedLetters,
      tempPlacedLetters,
      hasAreaRestriction: hasAreaRestriction,
      restrictedSide: restrictedSide,
    );

    if (!isValid) {
      return {
        'isValid': false,
        'word': '',
        'score': 0,
        'isFirstMove': isFirstMove,
      };
    }

    // İlk hamle için merkez kontrolü
    if (isFirstMove && !tempPlacedLetters.containsKey('7-7')) {
      return {
        'isValid': false,
        'word': '',
        'score': 0,
        'isFirstMove': isFirstMove,
        'error': 'İlk hamle merkez hücreden (7,7) geçmelidir!',
      };
    }

    // Kelime bilgisini al
    Map<String, dynamic> wordInfo = GameValidator.getWordInfo(
        board, tempPlacedLetters);

    return {
      'isValid': wordInfo['isValid'],
      'word': wordInfo['word'],
      'score': wordInfo['score'],
      'isFirstMove': isFirstMove,
      'allWords': wordInfo['allWords'] ?? [],
      // Tüm kelimelerin listesini de döndür
    };
  }

  /// Hamleyi tamamlar ve Firebase'e kaydeder
  Future<Map<String, dynamic>> confirmMove({
    required String gameId,
    required String userId,
    required String opponentId,
    required List<List<String>> board,
    required Map<String, Map<String, dynamic>> placedLetters,
    required Map<String, Map<String, dynamic>> tempPlacedLetters,
    required List<Letter> myLetters,
    required Map<String, Mine> mines,
  }) async {
    // Kelime bilgisini al
    Map<String, dynamic> wordInfo = GameValidator.getWordInfo(
        board, tempPlacedLetters);

    if (!wordInfo['isValid']) {
      return {
        'success': false,
        'error': 'Geçersiz kelime! Tüm kelimelerin Türkçe olduğundan emin olun.'
      };
    }

    int originalScore = wordInfo['score'];
    int finalScore = originalScore;
    bool transferPoints = false;
    bool cancelPoints = false;
    bool letterLoss = false;
    bool disableBonuses = false;

    // Mayın kontrolü
    List<Map<String, dynamic>> triggeredMines = [];

    for (var entry in tempPlacedLetters.entries) {
      final position = entry.key;
      print("Kontrol edilen pozisyon: $position");

      if (mines.containsKey(position)) {
        print("Mayın bulundu! Konum: $position, Tip: ${mines[position]!.type}");
        final mine = mines[position]!;

        if (!mine.triggered) {
          // Mayını tetikle
          print("Mayın tetikleniyor: ${mine.type}");

          switch (mine.type) {
            case MineType.pointDivision:
              finalScore = (originalScore * 0.3).round();
              print("Puan Bölünmesi uygulandı: $originalScore -> $finalScore");
              break;
            case MineType.pointTransfer:
              transferPoints = true;
              print(
                  "Puan Transferi uygulandı: $originalScore puan rakibe gidecek");
              break;
            case MineType.letterLoss:
              letterLoss = true;
              print("Harf Kaybı uygulandı");
              break;
            case MineType.bonusBlock:
              disableBonuses = true;
              if (originalScore != finalScore) {
                finalScore = originalScore; // Bonusları iptal et
              }
              print("Bonus Engelleme uygulandı");
              break;
            case MineType.wordCancel:
              cancelPoints = true;
              print("Kelime İptali uygulandı");
              break;
          }

          triggeredMines.add({
            'position': position,
            'type': mine.type
                .toString()
                .split('.')
                .last
          });

          // Mayını tetiklenmiş olarak işaretle
          await _firebaseService.updateMineStatus(gameId, position, true);
        }
      }
    }

    // Ödül kontrolü
    List<Map<String, dynamic>> collectedRewards = [];

    final gameState = await _firebaseService.loadGameState(gameId);
    final rewards = gameState.rewards;

    for (var entry in tempPlacedLetters.entries) {
      final position = entry.key;

      if (rewards.containsKey(position)) {
        final reward = rewards[position]!;

        if (!reward.collected) {
          print("Ödül bulundu! Konum: $position, Tip: ${reward.type}");

          // Ödülü topla
          await _firebaseService.updateRewardStatus(
            gameId,
            position,
            true, // collected
            userId, // collectedBy
            false, // used
          );

          collectedRewards.add({
            'position': position,
            'type': reward.type
                .toString()
                .split('.')
                .last
          });

          print("Ödül toplandı: ${reward.type}");
        }
      }
    }


    // Hamleyi Firebase'e kaydet
    Map<String, Map<String, dynamic>> newBoardCells = {};
    for (var entry in tempPlacedLetters.entries) {
      newBoardCells[entry.key] = {
        'char': entry.value['char'],
        'id': entry.value['id'],
        'point': entry.value['point'],
        'placedBy': userId,
      };
    }

    await _firebaseService.makeMove(
      gameId: gameId,
      userId: userId,
      opponentId: opponentId,
      newBoard: newBoardCells,
      score: finalScore,
      transferPoints: transferPoints,
      cancelPoints: cancelPoints,
    );

    // Kullanılan harfleri çıkar ve yeni harfler çek
    List<int> usedLetterIds = tempPlacedLetters.values.map((
        l) => l['id'] as int).toList();
    List<Letter> updatedLetters = myLetters.where((l) =>
    !usedLetterIds.contains(l.id)).toList();

    // Harf kaybı mayını tetiklendiyse
    if (letterLoss) {
      updatedLetters =
      await _letterService.resetLetters(gameId, userId, updatedLetters);
      print("Harf kaybı mayını tetiklendi, harfler sıfırlandı");
    } else {
      // Eğer gerekliyse, yeni harfler çek
      if (updatedLetters.length < MAX_LETTERS_PER_PLAYER) {
        updatedLetters = await _letterService.drawNewLetters(
            gameId,
            userId,
            updatedLetters,
            MAX_LETTERS_PER_PLAYER - updatedLetters.length
        );
        print("${MAX_LETTERS_PER_PLAYER -
            updatedLetters.length} yeni harf çekildi");
      }
    }

    final updatedGameState = await _firebaseService.loadGameState(gameId);
    final remainingLetterCount = updatedGameState.letterPool.length;

    // Oyun sonu kontrolü
    if (updatedLetters.isEmpty && remainingLetterCount == 0) {
      await _endGame(gameId, userId, opponentId, 'noLetters');
    }

    // Sonuç bilgilerini döndür
    return {
      'success': true,
      'score': finalScore,
      'word': wordInfo['word'],
      'transferPoints': transferPoints,
      'cancelPoints': cancelPoints,
      'letterLoss': letterLoss,
      'disableBonuses': disableBonuses,
      'triggeredMines': triggeredMines,
      'collectedRewards': collectedRewards,
      'updatedLetters': updatedLetters,
      'remainingLetterCount': remainingLetterCount,
    };
  }

  /// Pas geçer
  Future<bool> passTurn(String gameId, String userId, String opponentId,
      int consecutivePassCount) async {
    // Eğer arka arkaya 2 kez pas geçildiyse oyunu bitir
    if (consecutivePassCount + 1 >= MAX_CONSECUTIVE_PASSES) {
      await _endGame(gameId, userId, opponentId, 'consecutivePasses');
      return true; // Oyun bitti
    }

    // Sırayı rakibe geç
    await _firebaseService.passTurn(gameId, userId, opponentId);
    return false; // Oyun devam ediyor
  }

  /// Oyunu bitirir
  Future<void> _endGame(String gameId, String userId, String opponentId,
      String reason) async {
    // Oyun durumunu yükle
    final gameState = await _firebaseService.loadGameState(gameId);

    // Puanları hesapla
    int myFinalScore = gameState.scores[userId] ?? 0;
    int opponentFinalScore = gameState.scores[opponentId] ?? 0;

    // Eğer oyun harfler bittiği için bitiyorsa, kalan harflerin puanlarını hesapla
    if (reason == 'noLetters') {
      // Rakibin kalan harflerini al
      final opponentLetters = gameState.letters[opponentId] ?? [];

      // Rakibin kalan harflerinin puanlarını topla
      int remainingPoints = 0;
      for (var letter in opponentLetters) {
        remainingPoints += letter.point;
      }

      // Bu puanları kullanıcıya ekle, rakipten düş
      myFinalScore += remainingPoints;
      opponentFinalScore -= remainingPoints;
    }

    // Kazananı belirle
    String winner;
    if (myFinalScore > opponentFinalScore) {
      winner = userId;
    } else if (opponentFinalScore > myFinalScore) {
      winner = opponentId;
    } else {
      winner = 'draw'; // Beraberlik
    }

    // Oyun sonucunu Firebase'e kaydet
    await _firebaseService.endGame(
        gameId,
        reason,
        winner,
        {
          userId: myFinalScore,
          opponentId: opponentFinalScore,
        }
    );
  }

  /// Teslim olur
  Future<void> surrender(String gameId, String userId,
      String opponentId) async {
    await _firebaseService.surrender(gameId, userId, opponentId);
  }

  /// Ödül kullanır
  Future<bool> useReward(String gameId, String userId, String opponentId, Reward reward) async {
    try {
      switch (reward.type) {
        case RewardType.areaRestriction:
        // Rastgele sağ veya sol tarafı seç
          final restrictedSide = Random().nextBool() ? 'left' : 'right';
          await _firebaseService.applyAreaRestriction(
              gameId, userId, opponentId, restrictedSide);


          break;

        case RewardType.letterRestriction:
        // Opponent'ın mevcut harflerini al
          final gameState = await _firebaseService.loadGameState(gameId);
          final opponentLetters = gameState.letters[opponentId] ?? [];

          if (opponentLetters.isEmpty) {
            return false; // Rakibin elinde harf yok
          }

          // Rastgele 2 harf seç
          opponentLetters.shuffle(Random());
          final restrictedLetters = opponentLetters.take(min(2, opponentLetters.length)).toList();
          final restrictedIds = restrictedLetters.map((l) => l.id).toList();

          await _firebaseService.applyLetterRestriction(
                gameId, userId, opponentId, restrictedIds);
          break;

        case RewardType.extraMove:
        // Ekstra hamle özelliğini değiştiriyoruz: hamle tamamlandıktan sonra aktifleşecek
          await _firebaseService.applyExtraMove(gameId, userId);
          break;
      }

      // Ödülü kullanıldı olarak işaretle
      await _firebaseService.updateRewardStatus(gameId, reward.position, true, userId, true);

      return true;
    } catch (e) {
      debugPrint("Ödül kullanılırken hata: $e");
      return false;
    }
  }

  /// Mayınları yerleştirir
  Future<void> placeMines(String gameId) async {
    Random random = Random();
    Map<String, Map<String, dynamic>> mines = {};
    Set<String> positions = {
    }; // Benzersiz konumları tutmak için Set kullanıyoruz

    // Mayınların yerleştirileceği rastgele konumları belirle
    for (var mineType in MINE_TYPES) {
      String type = mineType['type'];
      int count = mineType['count'];

      print("Yerleştiriliyor: $count adet $type mayını");

      for (int i = 0; i < count; i++) {
        String position;
        int newRow, newCol;

        do {
          newRow = random.nextInt(BOARD_SIZE);
          newCol = random.nextInt(BOARD_SIZE);
          position = '$newRow-$newCol';
        } while (positions.contains(position) || (newRow == 7 && newCol == 7));

        positions.add(position);
        mines[position] = {
          'type': type,
          'triggered': false,
        };

        print("Mayın yerleştirildi: $type -> $position");
      }
    }

    // Firebase'e mayınları toplu olarak kaydet
    try {
      await _firebaseService.loadGameState(gameId).then((gameState) async {
        // Mines alanını daha önce başlatmak için boş bir değer atama
        bool hasMines = gameState.mines.isNotEmpty;

        if (!hasMines) {
          print("Mayınlar Firebase'e kaydediliyor - toplam ${mines
              .length} mayın");

          // Her bir mayını ayrı ayrı ekle
          for (var entry in mines.entries) {
            await _firebaseService.updateMineStatus(
                gameId,
                entry.key,
                false,
                mineType: entry.value['type']
            );
          }

          print("Mayınlar başarıyla kaydedildi");
        } else {
          print("Mayınlar zaten var, yeniden oluşturulmadı");
        }
      });
    } catch (e) {
      print("Mayın oluşturma hatası: $e");
    }
  }

  /// Ödülleri yerleştirir
  Future<void> placeRewards(String gameId) async {
    Random random = Random();
    Set<String> positions = {};
    Map<String, Map<String, dynamic>> rewards = {};

    // Ödüllerin yerleştirileceği rastgele konumları belirle
    for (var rewardType in REWARD_TYPES) {
      String type = rewardType['type'];
      int count = rewardType['count'];

      print("Yerleştiriliyor: $count adet $type ödülü");

      for (int i = 0; i < count; i++) {
        String position;
        int newRow, newCol;

        do {
          newRow = random.nextInt(BOARD_SIZE);
          newCol = random.nextInt(BOARD_SIZE);
          position = '$newRow-$newCol';
        } while (
        positions.contains(position) ||
            (newRow == 7 && newCol == 7)
        );

        positions.add(position);
        rewards[position] = {
          'type': type,
          'collected': false,
        };

        print("Ödül yerleştirildi: $type -> $position");
      }
    }

    // Firebase'e ödülleri toplu olarak kaydet
    try {
      await _firebaseService.loadGameState(gameId).then((gameState) async {
        // Rewards alanını daha önce başlatmak için boş bir değer atama
        bool hasRewards = gameState.rewards.isNotEmpty;

        if (!hasRewards) {
          print("Ödüller Firebase'e kaydediliyor - toplam ${rewards
              .length} ödül");

          // Her bir ödülü ayrı ayrı ekle
          for (var entry in rewards.entries) {
            await _firebaseService.updateRewardStatus(
                gameId,
                entry.key,
                false,
                null,
                false,
                rewardType: entry.value['type']
            );
          }

          print("Ödüller başarıyla kaydedildi");
        } else {
          print("Ödüller zaten var, yeniden oluşturulmadı");
        }
      });
    } catch (e) {
      print("Ödül oluşturma hatası: $e");
    }
  }
}