import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int remainingLettersCount = 86; // Initial count of letters in the pool
  bool isLoading = true;
  String opponentId = '';
  int myScore = 0;
  int opponentScore = 0;
  bool myTurn = false;

  // Letter pool with counts and points
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

  // Track the remaining letters in the pool
  Map<String, int> remainingLetters = {};
  List<Map<String, dynamic>> letterPoolFlat = [];

  @override
  void initState() {
    super.initState();
    _initializeLetterPool();
    _loadGameData();
    _setupGameListener();
  }

  void _initializeLetterPool() {
    // Initialize the remaining letters count based on the letterPool
    for (var letter in _letterPool) {
      remainingLetters[letter['char']] = letter['count'];

      // Create a flat list of all letters for random selection
      for (int i = 0; i < letter['count']; i++) {
        letterPoolFlat.add({
          "char": letter['char'],
          "point": letter['point'],
        });
      }
    }

    // Shuffle the letter pool
    letterPoolFlat.shuffle(Random());
  }

  Future<void> _loadGameData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final gameDoc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();

      if (!gameDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oyun bulunamadı!")),
        );
        Navigator.pop(context);
        return;
      }

      final gameData = gameDoc.data()!;

      // Get opponent ID
      final players = List<String>.from(gameData['players'] ?? []);
      opponentId = players.firstWhere((id) => id != widget.userId, orElse: () => '');

      // Get scores
      myScore = gameData['scores']?[widget.userId] ?? 0;
      opponentScore = gameData['scores']?[opponentId] ?? 0;

      // Get turn information
      myTurn = gameData['currentTurn'] == widget.userId;

      // Load board state
      if (gameData['board'] != null) {
        final boardData = Map<String, dynamic>.from(gameData['board']);
        for (var entry in boardData.entries) {
          final coords = entry.key.split('-');
          final row = int.parse(coords[0]);
          final col = int.parse(coords[1]);
          final letterData = Map<String, dynamic>.from(entry.value);

          setState(() {
            board[row][col] = letterData['char'];
            placedLetters[entry.key] = letterData;
          });
        }
      }

      // Load letter pool state
      if (gameData['letterPool'] != null) {
        final poolData = List<Map<String, dynamic>>.from(gameData['letterPool']);
        letterPoolFlat = poolData;
        remainingLettersCount = letterPoolFlat.length;
      }

      // Load player letters
      final lettersMap = gameData['letters'] ?? {};

      if (lettersMap[widget.userId] == null) {
        // Kullanıcının harfleri yoksa, havuzdan 7 harf dağıt
        await _distributeInitialLetters();
      } else {
        myLetters = List<Map<String, dynamic>>.from(lettersMap[widget.userId]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veri yüklenirken hata: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setupGameListener() {
    FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final gameData = snapshot.data()!;

      // Update scores
      setState(() {
        myScore = gameData['scores']?[widget.userId] ?? 0;
        opponentScore = gameData['scores']?[opponentId] ?? 0;
        myTurn = gameData['currentTurn'] == widget.userId;

        // Update letter pool count
        if (gameData['letterPool'] != null) {
          remainingLettersCount = (gameData['letterPool'] as List).length;
        }

        // Update player letters if they've changed
        if (gameData['letters'] != null && gameData['letters'][widget.userId] != null) {
          myLetters = List<Map<String, dynamic>>.from(gameData['letters'][widget.userId]);
        }

        // Update board state
        if (gameData['board'] != null) {
          final boardData = Map<String, dynamic>.from(gameData['board']);
          // Only update new letters
          for (var entry in boardData.entries) {
            if (!placedLetters.containsKey(entry.key)) {
              final coords = entry.key.split('-');
              final row = int.parse(coords[0]);
              final col = int.parse(coords[1]);
              final letterData = Map<String, dynamic>.from(entry.value);

              board[row][col] = letterData['char'];
              placedLetters[entry.key] = letterData;
            }
          }
        }
      });
    });
  }

  Future<void> _distributeInitialLetters() async {
    if (letterPoolFlat.isEmpty) return;

    // İlk 7 harfi al (havuzda daha az varsa mevcut sayıyı)
    final count = min(7, letterPoolFlat.length);
    final userLetters = letterPoolFlat.take(count).toList();

    // Dağıtılan harfleri havuzdan çıkar
    letterPoolFlat.removeRange(0, count);

    // Mevcut letters nesnesini al
    DocumentSnapshot gameDoc = await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .get();

    Map<String, dynamic> currentLetters = (gameDoc.data() as Map<String, dynamic>)['letters'] ?? {};


    // Kullanıcının harflerini güncelle, diğer oyuncunun harflerini koru
    currentLetters[widget.userId] = userLetters;

    // Firebase'i güncelle
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "letters": currentLetters,
      "letterPool": letterPoolFlat,
    });

    setState(() {
      myLetters = userLetters;
      remainingLettersCount = letterPoolFlat.length;
    });
  }

// Yeni harf çekme fonksiyonunu da düzelt
  Future<void> _drawNewLetters(int count) async {
    if (letterPoolFlat.isEmpty) return;

    final drawCount = min(count, letterPoolFlat.length);
    if (drawCount <= 0) return;

    final newLetters = letterPoolFlat.take(drawCount).toList();
    letterPoolFlat.removeRange(0, drawCount);

    final updatedLetters = [...myLetters, ...newLetters];

    // Mevcut letters nesnesini al
    DocumentSnapshot gameDoc = await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .get();

    Map<String, dynamic> currentLetters = (gameDoc.data() as Map<String, dynamic>)['letters'] ?? {};


    // Kullanıcının harflerini güncelle, diğer oyuncunun harflerini koru
    currentLetters[widget.userId] = updatedLetters;

    // Update Firebase
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "letters": currentLetters,
      "letterPool": letterPoolFlat,
    });

    // Yerel durumu güncelle
    setState(() {
      myLetters = updatedLetters;
      remainingLettersCount = letterPoolFlat.length;
    });
  }


// Hamle onaylama fonksiyonunu da düzelt
  Future<void> _confirmMove() async {
    if (placedLetters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir kelime oluşturun")),
      );
      return;
    }

    try {
      // Yerleştirilen harfler için puan hesapla
      int moveScore = 0;
      for (var letter in placedLetters.values) {
        moveScore += letter['point'] as int;
      }

      // Şu anki oyun verisini al
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();

      if (!gameDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oyun bulunamadı!")),
        );
        return;
      }

      // Mevcut tahta durumunu al
      Map<String, dynamic> currentBoard = (gameDoc.data() as Map<String, dynamic>)['board'] ?? {};


      // Yeni harfleri ekle
      currentBoard.addAll(placedLetters);

      // Firebase'i tahta durumu, puanlar ve sıra ile güncelle
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update({
        "board": currentBoard,
        "scores.${widget.userId}": FieldValue.increment(moveScore),
        "currentTurn": opponentId, // Sırayı rakibe geçir
        "lastAction": {
          "userId": widget.userId,
          "action": "move",
          "score": moveScore,
          "timestamp": FieldValue.serverTimestamp(),
        }
      });

      // Kullanılan harfleri çıkar
      myLetters.removeWhere((l) => placedLetters.values.any((pl) => pl['char'] == l['char'] && !placedLetters.values
          .where((other) => other != pl)
          .any((other) => other['char'] == l['char'])));

      setState(() {
        placedLetters = {}; // Onayladıktan sonra yerleştirilen harfleri temizle
        myTurn = false; // Sıranın geçtiğini kullanıcı arayüzünde güncelle
      });

      // Eğer gerekliyse, yeni harfler çek
      if (myLetters.length < 7) {
        await _drawNewLetters(7 - myLetters.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hamle onaylandı! $moveScore puan kazandın.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hamle onaylanırken hata: $e")),
      );
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF2C2077),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("👤 Sen", style: TextStyle(color: Colors.white)),
              Text("🏆 $myScore", style: const TextStyle(color: Colors.amber)),
            ],
          ),
          Column(
            children: [
              const Text("🔤 Kalan", style: TextStyle(color: Colors.white)),
              Text(
                "$remainingLettersCount",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("🤖 Rakip", style: TextStyle(color: Colors.white)),
              Text("🏆 $opponentScore", style: const TextStyle(color: Colors.amber)),
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

          // Determine cell color based on special cells
          Color cellColor = Colors.white;

          // Center cell (starting point)
          if (row == 7 && col == 7) {
            cellColor = Colors.purple[100]!;
          }
          // Double letter score
          else if ((row == 3 && (col == 0 || col == 7 || col == 14)) ||
              (row == 7 && (col == 3 || col == 11)) ||
              (row == 11 && (col == 0 || col == 7 || col == 14))) {
            cellColor = Colors.blue[100]!;
          }
          // Triple letter score
          else if ((row == 1 && (col == 5 || col == 9)) ||
              (row == 5 && (col == 1 || col == 5 || col == 9 || col == 13)) ||
              (row == 9 && (col == 1 || col == 5 || col == 9 || col == 13)) ||
              (row == 13 && (col == 5 || col == 9))) {
            cellColor = Colors.blue[300]!;
          }
          // Double word score
          else if ((row == 1 && (col == 1 || col == 13)) ||
              (row == 2 && (col == 2 || col == 12)) ||
              (row == 3 && (col == 3 || col == 11)) ||
              (row == 4 && (col == 4 || col == 10)) ||
              (row == 10 && (col == 4 || col == 10)) ||
              (row == 11 && (col == 3 || col == 11)) ||
              (row == 12 && (col == 2 || col == 12)) ||
              (row == 13 && (col == 1 || col == 13))) {
            cellColor = Colors.red[100]!;
          }
          // Triple word score
          else if ((row == 0 && (col == 0 || col == 7 || col == 14)) ||
              (row == 7 && (col == 0 || col == 14)) ||
              (row == 14 && (col == 0 || col == 7 || col == 14))) {
            cellColor = Colors.red[300]!;
          }

          // If there's a letter placed, change color to amber
          if (placed.isNotEmpty) {
            cellColor = Colors.amber;
          }

          return DragTarget<Map<String, dynamic>>(
            onWillAccept: (_) => placed.isEmpty && myTurn,
            onAccept: (data) {
              if (!myTurn) return;

              setState(() {
                placedLetters['$row-$col'] = data;
                myLetters.removeWhere((l) => l['char'] == data['char'] &&
                    !placedLetters.values.any((pl) => pl['char'] == l['char'] && pl != data));
              });
            },
            builder: (context, _, __) {
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: cellColor,
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
          _actionButton("Onayla", Icons.check, Colors.green, _confirmMove),
          _actionButton("Pas", Icons.pause, Colors.orange, _passMove),
          _actionButton("Teslim Ol", Icons.flag, Colors.redAccent, _surrender),
        ],
      ),
    );
  }

// Pas geçme fonksiyonunu düzelt
  Future<void> _passMove() async {
    if (!myTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şu anda senin sıran değil!")),
      );
      return;
    }

    try {
      // Şu anki oyun verisini al
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();

      if (!gameDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oyun bulunamadı!")),
        );
        return;
      }

      // Sırayı rakibe geç ve pas bilgisini kaydet
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update({
        "currentTurn": opponentId,
        "lastAction": {
          "userId": widget.userId,
          "action": "pass",
          "timestamp": FieldValue.serverTimestamp(),
        }
      });

      // Kullanıcı arayüzünde sırayı güncelle
      setState(() {
        myTurn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pas geçildi, sıra rakibe geçti.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pas geçerken hata: $e")),
      );
    }
  }
  Future<void> _surrender() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Teslim Ol"),
        content: const Text("Gerçekten teslim olmak istiyor musun? Bu oyunu kaybetmiş sayılacaksın."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Teslim Ol"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // End the game with surrender
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "status": "completed",
      "winner": opponentId,
      "endReason": "surrender",
      "endTime": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Oyun teslim olarak sona erdi.")),
    );

    Navigator.pop(context); // Return to previous screen
  }

  Widget _actionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: myTurn ? onPressed : null, // Disable buttons when it's not user's turn
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF3E2C8F),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

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