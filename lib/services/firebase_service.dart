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

      // Ekstra hamle kontrolü
      Map<String, dynamic>? gameData = gameDoc.data() as Map<String, dynamic>?;
      bool hasExtraMove = false;

      if (gameData != null &&
          gameData.containsKey('extraMove') &&
          gameData['extraMove'] != null &&
          gameData['extraMove']['active'] == true &&
          gameData['extraMove']['userId'] == userId) {

        // Oyuncunun ekstra hamle hakkı var
        // Ekstra hamle hakkı kullanıldı, sıfırla
        updates["extraMove"] = {
          "active": false,
          "userId": userId
        };

        // Sırayı rakibe geçir
        updates["currentTurn"] = opponentId;

        print("Ekstra hamle kullanıldı ve sıfırlandı.");
      } else {
        // Normal hamle
        // Oyuncunun ekstra hamle hakkı var mı kontrol et
        if (gameData != null &&
            gameData.containsKey('pendingExtraMove') &&
            gameData['pendingExtraMove'] != null &&
            gameData['pendingExtraMove'] == true) {

          // Ekstra hamle hakkı aktifleştir
          updates["extraMove"] = {
            "active": true,
            "userId": userId
          };

          // Bekleyen ekstra hamle hakkını temizle
          updates["pendingExtraMove"] = false;

          // Sıra hala aynı oyuncuda kalacak
          hasExtraMove = true;

          print("Ekstra hamle hakkı aktifleştirildi. Oyuncu bir hamle daha yapabilecek.");
        } else {
          // Normal hamle, sırayı rakibe geçir
          updates["currentTurn"] = opponentId;
          if (gameData != null &&
              gameData.containsKey('restrictions') &&
              gameData['restrictions'] != null &&
              gameData['restrictions']['letterRestriction'] != null) {

            Map<String, dynamic> letterRestriction = gameData['restrictions']['letterRestriction'];

            if (letterRestriction['pendingActivation'] == true &&
                letterRestriction['appliedTo'] == opponentId) {

              updates["restrictions.letterRestriction.active"] = true;
              updates["restrictions.letterRestriction.pendingActivation"] = false;

              print("Harf kısıtlaması aktifleştirildi. Rakip bu tur kısıtlı harflerini kullanamayacak.");
            }
          }
        }
      }
      // Firebase'i güncelle
      await _firestore.collection('games').doc(gameId).update(updates);

      // Kısıtlamaları kontrol et ve gerekirse sıfırla
      // Eğer ekstra hamle kullanıyorsa kısıtlamaları kontrol etmeye gerek yok
      if (!hasExtraMove) {
        await _checkAndResetLetterRestrictions(gameId, userId);
      }

    } catch (e) {
      throw Exception("Hamle yapılırken hata: $e");
    }
  }

  /// Ekstra hamle hakkı uygular
  Future<void> applyExtraMove(String gameId, String userId) async {
    try {
      // Ekstra hamle ödülü kullanıldığında, ilk önce bir flag ayarla
      // Oyuncu mevcut hamlesini tamamladıktan sonra ekstra hamle aktifleşecek
      await _firestore.collection('games').doc(gameId).update({
        "pendingExtraMove": true
      });

      print("Ekstra hamle hakkı tanımlandı. Mevcut hamle tamamlandıktan sonra aktifleşecek.");
    } catch (e) {
      throw Exception("Ekstra hamle hakkı uygulanırken hata: $e");
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


      // Firebase güncellemelerini hazırla
      Map<String, dynamic> updates = {
        "consecutivePassCount": newPassCount,
        "lastAction": {
          "userId": userId,
          "action": "pass",
          "timestamp": FieldValue.serverTimestamp(),
        }
      };

      // Ekstra hamle kontrolü
      Map<String, dynamic>? gameData = gameDoc.data() as Map<String, dynamic>?;
      bool hasExtraMove = false;

      if (gameData != null &&
          gameData.containsKey('extraMove') &&
          gameData['extraMove'] != null &&
          gameData['extraMove']['active'] == true &&
          gameData['extraMove']['userId'] == userId) {
        // Ekstra hamle kullanıldı, sıfırla
        updates["extraMove"] = {
          "active": false,
          "userId": userId
        };
        updates["currentTurn"] = opponentId;
        print("Ekstra hamle pas geçildiğinde sıfırlandı.");
      }else{
        // Normal pas geçme
        // Oyuncunun bekleyen ekstra hamle hakkı var mı kontrol et
        if (gameData != null &&
            gameData.containsKey('pendingExtraMove') &&
            gameData['pendingExtraMove'] != null &&
            gameData['pendingExtraMove'] == true) {

          // Ekstra hamle hakkı aktifleştir
          updates["extraMove"] = {
            "active": true,
            "userId": userId
          };

          // Bekleyen ekstra hamle hakkını temizle
          updates["pendingExtraMove"] = false;

          // Sıra hala aynı oyuncuda kalacak
          hasExtraMove = true;

          print("Ekstra hamle hakkı aktifleştirildi. Oyuncu bir hamle daha yapabilecek.");
        }else {
          // Normal pas geçme, sırayı rakibe geçir
          updates["currentTurn"] = opponentId;

          if (gameData != null &&
              gameData.containsKey('restrictions') &&
              gameData['restrictions'] != null &&
              gameData['restrictions']['letterRestriction'] != null) {

            Map<String, dynamic> letterRestriction = gameData['restrictions']['letterRestriction'];

            if (letterRestriction['pendingActivation'] == true &&
                letterRestriction['appliedTo'] == opponentId) {

              updates["restrictions.letterRestriction.active"] = true;
              updates["restrictions.letterRestriction.pendingActivation"] = false;

              print("Harf kısıtlaması aktifleştirildi. Rakip bu tur kısıtlı harflerini kullanamayacak.");
            }
          }
        }
      }

      await _firestore.collection('games').doc(gameId).update(updates);


      // Kısıtlamaları kontrol et ve gerekirse sıfırla
      // Eğer ekstra hamle kullanıyorsa kısıtlamaları kontrol etmeye gerek yok
      if (!hasExtraMove) {
        await _checkAndResetLetterRestrictions(gameId, userId);
      }

    } catch (e) {
      throw Exception("Pas geçilirken hata: $e");
    }
  }

  /// Harf kısıtlamalarını kontrol eder ve gerekirse sıfırlar (1 tur sonra)
  Future<void> _checkAndResetLetterRestrictions(String gameId, String currentTurnPlayerId) async {
    try {
      // Oyun durumunu al
      DocumentSnapshot gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) return;

      Map<String, dynamic>? gameData = gameDoc.data() as Map<String, dynamic>?;
      if (gameData == null || !gameData.containsKey('restrictions')) return;

      Map<String, dynamic> restrictions = Map<String, dynamic>.from(gameData['restrictions']);

      // Harf kısıtlaması kontrolü - kısıtlamayı uygulayan oyuncu hamle yaptığında kısıtlama kaldırılmalı
      if (restrictions.containsKey('letterRestriction') &&
          restrictions['letterRestriction'] != null &&
          restrictions['letterRestriction']['active'] == true ) {

        if (restrictions['letterRestriction']['appliedTo'] == currentTurnPlayerId) {
          await _firestore.collection('games').doc(gameId).update({
            "restrictions.letterRestriction.active": false,
            "restrictions.letterRestriction.pendingActivation": false
          });

          print("Harf kısıtlaması süresi doldu ve devre dışı bırakıldı.");
        }
      }

      // Bölge kısıtlaması kontrolü - kısıtlamayı uygulayan oyuncu hamle yaptığında kısıtlama kaldırılmalı
      if (restrictions.containsKey('areaRestriction') &&
          restrictions['areaRestriction'] != null &&
          restrictions['areaRestriction']['active'] == true ) {
        // Süresi doldu, sıfırla
        if (restrictions['areaRestriction']['appliedTo'] ==
            currentTurnPlayerId) {
          await _firestore.collection('games').doc(gameId).update({
            "restrictions.areaRestriction.active": false
          });

          print("Bölge kısıtlaması süresi doldu ve devre dışı bırakıldı.");
        }
      }
    } catch (e) {
      print("Kısıtlamaları kontrol ederken hata: $e");
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
        "turnsRemaining": 1,
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
      // Kısıtlamayı hemen aktif etmiyoruz, rakibin sırası geldiğinde aktif olacak
      await _firestore.collection('games').doc(gameId).update({
        "restrictions.letterRestriction": {
          "active": false, // Başlangıçta aktif değil
          "pendingActivation": true, // Aktivasyon bekliyor
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

}