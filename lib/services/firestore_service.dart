import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _letterPool = [
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

  Future<void> initializeLetterPool(String gameId) async {
    List<Map<String, dynamic>> fullPool = [];

    for (var item in _letterPool) {
      for (int i = 0; i < item['count']; i++) {
        fullPool.add({"char": item['char'], "point": item['point']});
      }
    }

    fullPool.shuffle(Random());

    // Oyuncuları al
    final gameDoc = await _firestore.collection('games').doc(gameId).get();
    final players = List<String>.from(gameDoc['players']);
    final player1 = players[0];
    final player2 = players[1];

    // İlk 14 harfi dağıt
    final lettersForPlayer1 = fullPool.take(7).toList();
    final lettersForPlayer2 = fullPool.skip(7).take(7).toList();
    final remainingPool = fullPool.skip(14).toList();

    await _firestore.collection('games').doc(gameId).update({
      'letters': {
        player1: lettersForPlayer1,
        player2: lettersForPlayer2,
      },
      'letterPool': remainingPool, // 🔥 kalan harfleri de kaydediyoruz
    });
  }


}
