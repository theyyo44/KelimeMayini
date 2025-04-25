import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kelime_mayinlari/screens/game_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  User? currentUser;
  StreamSubscription<QuerySnapshot>? _searchSub;
  bool hasCreatedGame = false; // Sadece bir kez oyun oluşturmak için

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _searchForOpponent();
  }

  Future<void> _searchForOpponent() async {
    if (currentUser == null) return;

    _searchSub = _firestore
        .collection('games')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .listen((snapshot) async {
      if (_searchSub == null || hasCreatedGame) return;

      for (var doc in snapshot.docs) {
        final players = List<String>.from(doc['players'] ?? []);
        if (players.length == 1 && players.first != currentUser!.uid) {
          // 🎯 Eşleş!
          hasCreatedGame = true;
          players.shuffle(); // sıralamayı rastgele yap
          final starterUid = players.first;

          players.add(currentUser!.uid);
          await _firestore.collection('games').doc(doc.id).update({
            'players': players,
            'status': 'active',
            'currentTurn': starterUid,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          _searchSub?.cancel();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(
                gameId: doc.id,
                userId: currentUser!.uid,
              ),
            ),
          );
          return;
        }
      }

      // ❗Eğer eşleşme yoksa ve kullanıcı zaten bir "waiting" oyunda değilse
      final existing = await _firestore
          .collection('games')
          .where('status', isEqualTo: 'waiting')
          .where('players', arrayContains: currentUser!.uid)
          .get();

      if (existing.docs.isEmpty && !hasCreatedGame) {
        hasCreatedGame = true;

        final newGameRef = await _firestore.collection('games').add({
          'players': [currentUser!.uid],
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'duration': 300,
          'winner': null,
        });

        print('✅ Yeni oyun oluşturuldu: ${newGameRef.id}');
      }
    });
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff3E2C8F),
      body: Center(
        child: Text(
          "Eşleşme aranıyor...",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
