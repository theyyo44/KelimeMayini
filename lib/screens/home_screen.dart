// home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'new_game_screen.dart';
import 'my_games_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({required this.user, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DocumentReference userDoc;

  String username = "Yükleniyor...";
  int wins = 0;
  int matches = 0;
  int points = 0;

  @override
  @override
  void initState() {
    super.initState();
    userDoc = _firestore.collection('users').doc(widget.user.uid);
    userDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          username = snapshot['username'] ?? "Bilinmiyor";
          wins = snapshot['wins'] ?? 0;
          matches = snapshot['matches'] ?? 0;
          points = snapshot['points'] ?? 0;
        });
      }
    });
  }



  double get winRate => matches == 0 ? 0 : (wins / matches) * 100;

  void _showDurationSelector({required bool isShortGame}) {
    final durations = isShortGame ? ["2 Dakika", "5 Dakika"] : ["12 Saat", "24 Saat"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.deepPurple.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Süre Seç",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ...durations.map((label) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewGameScreen(durationSeconds: _parseDuration(label)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(label, style: const TextStyle(fontSize: 18)),
                  ),
                ))
              ],
            ),
          ),
        );
      },
    );
  }

  int _parseDuration(String label) {
    if (label.contains("2")) return 120;
    if (label.contains("5")) return 300;
    if (label.contains("12")) return 43200;
    if (label.contains("24")) return 86400;
    return 300; // default
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Çıkış Yap",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hoş geldin, $username",
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatTile("Toplam Puan", points.toString()),
            _buildStatTile("Kazanma Oranı", "%${winRate.toStringAsFixed(1)}"),
            _buildStatTile("Oynadığı Maç", matches.toString()),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyGamesScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Oyunlarım", style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showDurationSelector(isShortGame: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Uzun Oyun", style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _showDurationSelector(isShortGame: true),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Kısa Oyun", style: TextStyle(fontSize: 18)),
                  ),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


}
