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

  Future<String> _getOpponentUsername(String opponentId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(opponentId).get();
      if (doc.exists && doc.data()!.containsKey('username')) {
        return doc.data()!['username'] as String;
      }
      return "Bilinmeyen";
    } catch (e) {
      return "Hata";
    }
  }

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

            if (status == 'completed') {
              // Bitmiş oyunlar için özel görünüm
              final List<dynamic> players = data['players'] ?? [];
              final String opponentId = players.firstWhere(
                    (id) => id != currentUser.uid,
                orElse: () => '',
              );

              final scores = data['scores'] as Map<String, dynamic>? ?? {};
              final myScore = scores[currentUser.uid] ?? 0;
              final opponentScore = scores[opponentId] ?? 0;

              final winner = data['winner'];
              final isWinner = winner == currentUser.uid;
              final isDraw = winner == 'draw';

              // Bitiş zamanı
              final endTime = (data['endTime'] as Timestamp?)?.toDate();
              final endTimeText = endTime != null
                  ? "${endTime.day}/${endTime.month}/${endTime.year} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}"
                  : "Bilinmiyor";

              // Oyun sonucu icon ve renk
              IconData resultIcon;
              Color resultColor;
              String resultText;

              if (isDraw) {
                resultIcon = Icons.handshake;
                resultColor = Colors.orange;
                resultText = "Berabere";
              } else if (isWinner) {
                resultIcon = Icons.emoji_events;
                resultColor = Colors.green;
                resultText = "Kazandın!";
              } else {
                resultIcon = Icons.sentiment_dissatisfied;
                resultColor = Colors.red;
                resultText = "Kaybettin";
              }

              return FutureBuilder<String>(
                future: _getOpponentUsername(opponentId),
                builder: (context, usernameSnapshot) {
                  final opponentUsername = usernameSnapshot.data ?? "Yükleniyor...";

                  return Card(
                    color: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: resultColor,
                        child: Icon(
                          resultIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        resultText,
                        style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Rakip: $opponentUsername",
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Skor: $myScore",
                                style: TextStyle(
                                  color: isWinner ? Colors.green : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                " - ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "$opponentScore",
                                style: TextStyle(
                                  color: !isWinner && !isDraw ? Colors.red : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Bitiş: $endTimeText",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
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
            } else {
              // Aktif ve bekleyen oyunlar için mevcut görünüm
              final timestamp = (data['updatedAt'] as Timestamp?)?.toDate();
              final lastUpdated = timestamp != null
                  ? "\nSon güncelleme: ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}"
                  : "";
              final turnText = status == 'waiting'
                  ? "Eşleşme bekleniyor"
                  : (data['currentTurn'] == currentUser.uid ? "Senin sıran" : "Rakipte sıra");

              return Card(
                color: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    turnText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Oyun ID: ${game.id}$lastUpdated",
                    style: const TextStyle(color: Colors.white70),
                  ),
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
            }
          },
        );
      },
    );
  }
}