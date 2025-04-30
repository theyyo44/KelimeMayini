import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../services/firebase_service.dart'; // Doğru import yolu
import '../services/letter_service.dart';   // Doğru import yolu
import '../utils/constants.dart';         // Harf havuzu için constants.dart kullan

// Köprü görevi gören sınıf - Eski kodu desteklemek için
class FirestoreService {
  final FirebaseService _firebaseService = FirebaseService();
  late final LetterService _letterService;

  FirestoreService() {
    _letterService = LetterService(_firebaseService);
    print("FirestoreService köprüsü başlatıldı");
  }

  // Orijinal fonksiyon - Yeni servislere yönlendirilir
  Future<void> initializeLetterPool(String gameId) async {
    print("initializeLetterPool çağrıldı, yeni yapıya yönlendiriliyor...");
    try {
      // Yeni yapımızdaki servisleri kullanarak işlemi gerçekleştir
      await _letterService.initializeGameLetters(gameId);
      print("Harfler başarıyla dağıtıldı");
    } catch (e) {
      print("Hata: Harfler dağıtılırken bir sorun oluştu: $e");
      rethrow; // Hatayı yeniden fırlat
    }
  }

  // Harf havuzu durumunu kontrol eden yardımcı metod (debug için)
  Future<int> checkRemainingLetters(String gameId) async {
    try {
      final gameDoc = await FirebaseFirestore.instance.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        print("Oyun belgesi bulunamadı");
        return 0;
      }

      final data = gameDoc.data();
      if (data == null || !data.containsKey('letterPool')) {
        print("Harf havuzu verisi bulunamadı");
        return 0;
      }

      final letterPool = data['letterPool'] as List;
      print("Firestore'da kalan harf sayısı: ${letterPool.length}");
      return letterPool.length;
    } catch (e) {
      print("Harf sayısı kontrol edilirken hata: $e");
      return -1;
    }
  }
}