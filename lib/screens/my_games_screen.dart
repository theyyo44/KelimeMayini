import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'game_screen.dart';

class MyGamesScreen extends StatelessWidget {
  const MyGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade900,
        appBar: AppBar(
          title: const Text("Oyunlarım"),
          backgroundColor: Colors.deepPurple,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Bekleyen"),
              Tab(text: "Aktif"),
              Tab(text: "Bitmiş"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GameList(status: 'waiting'),
            _GameList(status: 'active'),
            _GameList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _GameList extends StatelessWidget {
  final String status;

  const _GameList({required this.status});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final gamesRef = FirebaseFirestore.instance.collection('games');

    Query baseQuery = gamesRef.where('players', arrayContains: currentUser!.uid);
    if (status == 'active') {
      baseQuery = baseQuery.where('status', isEqualTo: 'active').where('winner', isEqualTo: null);
    } else {
      baseQuery = baseQuery.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: baseQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final games = snapshot.data?.docs ?? [];
        if (games.isEmpty) {
          return const Center(
            child: Text("Oyun bulunamadı", style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            final data = game.data() as Map<String, dynamic>;
            final timestamp = (data['updatedAt'] as Timestamp?)?.toDate();
            final lastUpdated = timestamp != null ? "\nSon güncelleme: ${timestamp.hour}:${timestamp.minute}" : "";
            final turnText = status == 'waiting'
                ? "Eşleşme bekleniyor"
                : (data['currentTurn'] == currentUser.uid ? "Senin sıran" : "Rakipte sıra");

            return Card(
              color: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(turnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("Oyun ID: ${game.id}$lastUpdated", style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(gameId: game.id, userId: currentUser.uid),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
