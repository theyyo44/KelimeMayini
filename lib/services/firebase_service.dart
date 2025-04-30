// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_state.dart'; // BoardCellModel bu dosyada
import '../models/letter.dart';
import '../models/mine.dart';
import '../models/reward.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Oyun durumunu Firestore'dan yükler
  Future<GameState> loadGameState(String gameId) async {
    try {
      final gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception("Oyun bulunamadı!");
      }

      return GameState.fromMap(gameId, gameDoc.data()!);
    } catch (e) {
      throw Exception("Oyun yüklenirken hata: $e");
    }
  }

  /// Oyun durumunu gerçek zamanlı olarak izler
  Stream<GameState> gameStateStream(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception("Oyun bulunamadı!");
      }
      return GameState.fromMap(gameId, snapshot.data()!);
    });
  }

  /// Kullanıcının mevcut harflerini günceller
  Future<void> updateUserLetters(String gameId, String userId, List<Letter> letters) async {
    try {
      // Mevcut letters nesnesini al
      DocumentSnapshot gameDoc = await _firestore.collection('games').doc(gameId).get();

      Map<String, dynamic> currentLetters = (gameDoc.data() as Map<String, dynamic>)['letters'] ?? {};

      // Kullanıcının harflerini güncelle, diğer oyuncunun harflerini koru
      currentLetters[userId] = letters.map((e) => e.toMap()).toList();

      // Firebase'i güncelle
      await _firestore.collection('games').doc(gameId).update({
        "letters": currentLetters,
      });
    } catch (e) {
      throw Exception("Harfler güncellenirken hata: $e");
    }
  }

  /// Harf havuzunu günceller
  Future<void> updateLetterPool(String gameId, List<Letter> letterPool) async {
    try {
      final letterPoolMap = letterPool.map((e) => {
        'char': e.char,
        'point': e.point,
      }).toList();

      print("Harf havuzu güncelleniyor. Yeni harf sayısı: ${letterPool.length}");

      await _firestore.collection('games').doc(gameId).update({
        "letterPool": letterPoolMap,
      });

      print("Harf havuzu güncellendi.");
    } catch (e) {
      print("Hata: Harf havuzu güncellenirken hata: $e");
      throw Exception("Harf havuzu güncellenirken hata: $e");
    }
  }

  /// Hamle yapar ve tahtayı günceller
  Future<void> makeMove({
    required String gameId,
    required String userId,
    required String opponentId,
    required Map<String, Map<String, dynamic>> newBoard,
    required int score,
    bool transferPoints = false,
    bool cancelPoints = false,
  }) async {
    try {
      // Şu anki oyun verisini al
      DocumentSnapshot gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception("Oyun bulunamadı!");
      }

      // Mevcut tahta durumunu al
      Map<String, dynamic> currentBoard = (gameDoc.data() as Map<String, dynamic>)['board'] ?? {};

      // Yeni harfleri ekle
      currentBoard.addAll(newBoard);

      // Firebase güncellemelerini hazırla
      Map<String, dynamic> updates = {
        "board": currentBoard,
        "currentTurn": opponentId, // Sırayı rakibe geçir
        "lastAction": {
          "userId": userId,
          "action": "move",
          "score": score,
          "timestamp": FieldValue.serverTimestamp(),
        },
        "consecutivePassCount": 0, // Hamle yapıldı, pas sayacını sıfırla
      };

      // Puan güncellemeleri
      if (transferPoints) {
        updates["scores.$opponentId"] = FieldValue.increment(score);
      } else if (!cancelPoints) {
        updates["scores.$userId"] = FieldValue.increment(score);
      }

      // Firebase'i güncelle
      await _firestore.collection('games').doc(gameId).update(updates);
    } catch (e) {
      throw Exception("Hamle yapılırken hata: $e");
    }
  }

  /// Pas geçer
  Future<void> passTurn(String gameId, String userId, String opponentId) async {
    try {
      // Şu anki oyun verisini al
      DocumentSnapshot gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception("Oyun bulunamadı!");
      }

      // Mevcut pas sayısını al
      int currentPassCount = (gameDoc.data() as Map<String, dynamic>)['consecutivePassCount'] ?? 0;
      int newPassCount = currentPassCount + 1;

      // Sırayı rakibe geç ve pas bilgisini kaydet
      await _firestore.collection('games').doc(gameId).update({
        "currentTurn": opponentId,
        "consecutivePassCount": newPassCount,
        "lastAction": {
          "userId": userId,
          "action": "pass",
          "timestamp": FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      throw Exception("Pas geçilirken hata: $e");
    }
  }

  /// Oyunu sonlandırır
  Future<void> endGame(String gameId, String reason, String winner, Map<String, int> finalScores) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        "status": "completed",
        "endReason": reason,
        "endTime": FieldValue.serverTimestamp(),
        "winner": winner,
        "finalScores": finalScores,
      });
    } catch (e) {
      throw Exception("Oyun sonlandırılırken hata: $e");
    }
  }

  /// Teslim olur
  Future<void> surrender(String gameId, String userId, String opponentId) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        "status": "completed",
        "winner": opponentId,
        "endReason": "surrender",
        "endTime": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Teslim olurken hata: $e");
    }
  }

  /// Mayın durumunu günceller
  Future<void> updateMineStatus(String gameId, String position, bool triggered, {String? mineType}) async {
    try {
      if (mineType != null) {
        // Yeni mayın ekleniyor
        await _firestore.collection('games').doc(gameId).update({
          "mines.$position": {
            'type': mineType,
            'triggered': triggered
          }
        });
        print("Mayın eklendi: $position, tip: $mineType");
      } else {
        // Mevcut mayın güncelleniyor
        await _firestore.collection('games').doc(gameId).update({
          "mines.$position.triggered": triggered
        });
        print("Mayın güncellendi: $position, tetiklendi: $triggered");
      }
    } catch (e) {
      print("Mayın durumu güncellenirken hata: $e");
      throw Exception("Mayın durumu güncellenirken hata: $e");
    }
  }

  /// Ödül durumunu günceller
  Future<void> updateRewardStatus(String gameId, String position, bool collected, String? collectedBy, bool used, {String? rewardType}) async {
    try {
      Map<String, dynamic> updates = {};

      if (rewardType != null) {
        // Yeni ödül ekleniyor
        updates["rewards.$position"] = {
          'type': rewardType,
          'collected': collected,
        };
        print("Ödül eklendi: $position, tip: $rewardType");
      } else {
        // Mevcut ödül güncelleniyor
        updates["rewards.$position.collected"] = collected;
        print("Ödül güncellendi: $position, toplandı: $collected");
      }

      if (collectedBy != null) {
        updates["rewards.$position.collectedBy"] = collectedBy;
      }

      if (used) {
        updates["rewards.$position.used"] = true;
      }

      await _firestore.collection('games').doc(gameId).update(updates);
    } catch (e) {
      print("Ödül durumu güncellenirken hata: $e");
      throw Exception("Ödül durumu güncellenirken hata: $e");
    }
  }

  /// Bölge kısıtlaması uygular
  Future<void> applyAreaRestriction(String gameId, String appliedBy, String appliedTo, String side) async {
    try {
      // Önce restrictions'ı oku
      DocumentSnapshot gameDoc = await _firestore.collection('games').doc(gameId).get();

      Map<String, dynamic>? gameData = gameDoc.data() as Map<String, dynamic>?;
      Map<String, dynamic> restrictions = {};

      if (gameData != null && gameData.containsKey('restrictions')) {
        restrictions = Map<String, dynamic>.from(gameData['restrictions']);
      }

      // Mevcut kısıtlamalara bölge kısıtlamasını ekle
      restrictions['areaRestriction'] = {
        "active": true,
        "side": side,
        "appliedBy": appliedBy,
        "appliedTo": appliedTo,
        "expiresAt": FieldValue.serverTimestamp(),
      };

      // Güncellenmiş kısıtlamaları kaydet
      await _firestore.collection('games').doc(gameId).update({
        "restrictions": restrictions
      });
    } catch (e) {
      throw Exception("Bölge kısıtlaması uygulanırken hata: $e");
    }
  }

  /// Harf kısıtlaması uygular
  Future<void> applyLetterRestriction(String gameId, String appliedBy, String appliedTo, List<int> letterIds) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        "restrictions.letterRestriction": {
          "active": true,
          "letterIds": letterIds,
          "appliedBy": appliedBy,
          "appliedTo": appliedTo,
          "expiresAt": FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      throw Exception("Harf kısıtlaması uygulanırken hata: $e");
    }
  }

  /// Ekstra hamle hakkı uygular
  Future<void> applyExtraMove(String gameId, String userId) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        "extraMove": {
          "userId": userId,
          "active": true,
        }
      });
    } catch (e) {
      throw Exception("Ekstra hamle hakkı uygulanırken hata: $e");
    }
  }
}