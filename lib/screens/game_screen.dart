import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelime_mayinlari/screens/home_screen.dart';
import 'package:kelime_mayinlari/services/firestore_service.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  final String gameId;
  final String userId;

  const GameScreen({super.key, required this.gameId, required this.userId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<List<String>> board = List.generate(15, (_) => List.filled(15, ''));
  List<Map<String, dynamic>> myLetters = [];
  Map<String, Map<String, dynamic>> placedLetters = {};

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

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final doc = await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .get();

    final data = doc.data();
    if (data == null) return;

    final lettersMap = data['letters'] ?? {};

    if (lettersMap[widget.userId] == null) {
      // Harf atanmadıysa, ver
      final allLetters = <Map<String, dynamic>>[];

      for (var item in _letterPool) {
        for (int i = 0; i < item['count']; i++) {
          allLetters.add({
            "char": item['char'],
            "point": item['point'],
          });
        }
      }

      allLetters.shuffle(Random());
      final userLetters = allLetters.take(7).toList();

      // Firestore'a yaz
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .set({
        "letters": {widget.userId: userLetters},
      }, SetOptions(merge: true));

      myLetters = userLetters;
    } else {
      myLetters = List<Map<String, dynamic>>.from(lettersMap[widget.userId]);
    }

    setState(() {});
  }





  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF2C2077),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 Sen", style: TextStyle(color: Colors.white)),
              Text("🏆 0", style: TextStyle(color: Colors.amber)),
            ],
          ),
          const Column(
            children: [
              Text("🔤 Kalan", style: TextStyle(color: Colors.white)),
              Text("86", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("🤖 Rakip", style: TextStyle(color: Colors.white)),
              Text("🏆 0", style: TextStyle(color: Colors.amber)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 15,
        ),
        itemCount: 225,
        itemBuilder: (context, index) {
          final row = index ~/ 15;
          final col = index % 15;
          final placed = placedLetters['$row-$col']?['char'] ?? board[row][col];

          return DragTarget<Map<String, dynamic>>(
            onAccept: (data) {
              setState(() {
                placedLetters['$row-$col'] = data;
                myLetters.removeWhere((l) => l['char'] == data['char']);
              });
            },
            builder: (context, _, __) {
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: placed.isEmpty ? Colors.white : Colors.amber,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                alignment: Alignment.center,
                child: Text(
                  placed,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLetters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.indigo[800],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: myLetters.map((letter) {
          return Draggable<Map<String, dynamic>>(
            data: letter,
            feedback: _buildLetterTile(letter),
            childWhenDragging: _buildLetterTile({"char": "", "point": ""}),
            child: _buildLetterTile(letter),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildLetterTile(Map<String, dynamic> letter) {
    return Container(
      width: 44,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter['char'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(
              (letter['point'] ?? '').toString(),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton("Onayla", Icons.check, Colors.green),
          _actionButton("Pas", Icons.pause, Colors.orange),
          _actionButton("Teslim Ol", Icons.flag, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$text butonuna tıklandı.")),
        );
      },
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2C8F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text(
          "Kelime Mayınları",
          style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 8),
          _buildBoard(),
          const SizedBox(height: 8),
          _buildLetters(),
          _buildActions(),
        ],
      ),
    );
  }
}
