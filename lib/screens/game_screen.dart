import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
  Map<String, Map<String, dynamic>> tempPlacedLetters = {}; // Geçici yerleştirilen harfler
  int remainingLettersCount = 86; // Initial count of letters in the pool
  bool isLoading = true;
  String opponentId = '';
  int myScore = 0;
  int opponentScore = 0;
  bool myTurn = false;

  // Kelime listesi
  Set<String> validWords = {};
  bool isWordValid = false;
  String currentWord = '';
  int currentWordScore = 0;

  // Mayın ve Ödüller
  Map<String, Map<String, dynamic>> mines = {};
  List<Map<String, dynamic>> rewards = [];

  // Oyun durumu izleme
  int consecutivePassCount = 0;
  bool gameEnded = false;

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

  int nextLetterId = 0;

  @override
  void initState() {
    super.initState();
    _loadWordList();
    _initializeLetterPool();
    _loadGameData();
    _setupGameListener();
    _setupMinesAndRewards();
  }

  Future<void> _loadWordList() async {
    try {
      // Load the Turkish word list from assets
      final String data = await rootBundle.loadString('assets/turkish_words.txt');
      final List<String> words = LineSplitter.split(data).toList();

      validWords = Set<String>.from(words);
    } catch (e) {
      debugPrint('Error loading word list: $e');
    }
  }

  void _setupMinesAndRewards() {
    // Mayınların yerleştirilmesi
    _placeMines([
      {'type': 'pointDivision', 'count': 5}, // Puan Bölünmesi
      {'type': 'pointTransfer', 'count': 4}, // Puan Transferi
      {'type': 'letterLoss', 'count': 3},    // Harf Kaybı
      {'type': 'bonusBlock', 'count': 2},    // Ekstra Hamle Engeli
      {'type': 'wordCancel', 'count': 2},    // Kelime İptali
    ]);

    // Ödüllerin yerleştirilmesi
    _placeRewards([
      {'type': 'areaRestriction', 'count': 2}, // Bölge Yasağı
      {'type': 'letterRestriction', 'count': 3}, // Harf Yasağı
      {'type': 'extraMove', 'count': 2},       // Ekstra Hamle Jokeri
    ]);
  }

  void _placeMines(List<Map<String, dynamic>> mineTypes) {
    Random random = Random();
    List<String> positions = [];

    // Mayınların yerleştirileceği rastgele konumları belirle
    for (var mineType in mineTypes) {
      for (int i = 0; i < mineType['count']; i++) {
        String position;
        int newRow;
        int newCol;

        do {
          newRow = random.nextInt(15);
          newCol = random.nextInt(15);
          position = '$newRow-$newCol';
        } while (positions.contains(position) || (newRow == 7 && newCol == 7)); // Merkezi boş bırak

        positions.add(position);
        mines[position] = {
          'type': mineType['type'],
          'triggered': false,
        };
      }
    }
  }

  void _placeRewards(List<Map<String, dynamic>> rewardTypes) {
    Random random = Random();
    List<String> positions = [];

    // Ödüllerin yerleştirileceği rastgele konumları belirle
    for (var rewardType in rewardTypes) {
      for (int i = 0; i < rewardType['count']; i++) {
        String position;
        int newRow;
        int newCol;

        do {
          newRow = random.nextInt(15);
          newCol = random.nextInt(15);
          position = '$newRow-$newCol';
        } while (positions.contains(position) ||
            mines.containsKey(position) ||
            (newRow == 7 && newCol == 7)); // Merkezi ve mayınları boş bırak

        positions.add(position);

        // Ödülü Firebase'e ekle
        FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .update({
          "rewards.$position": {
            'type': rewardType['type'],
            'collected': false,
          }
        });
      }
    }
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

      // Load mines state if exists
      if (gameData['mines'] != null) {
        mines = Map<String, Map<String, dynamic>>.from(gameData['mines']);
      }

      // Load rewards state if exists
      if (gameData['rewards'] != null) {
        final Map<String, dynamic> rewardsData = gameData['rewards'];
        for (var entry in rewardsData.entries) {
          if (entry.value['collected'] == true && entry.value['collectedBy'] == widget.userId) {
            rewards.add({
              'type': entry.value['type'],
              'position': entry.key,
            });
          }
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

      // Get consecutive pass count
      consecutivePassCount = gameData['consecutivePassCount'] ?? 0;
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
        consecutivePassCount = gameData['consecutivePassCount'] ?? 0;

        // Check if game ended
        if (gameData['status'] == 'completed') {
          gameEnded = true;
          // Show game end dialog
          _showGameEndDialog(gameData['winner'] == widget.userId, gameData['endReason']);
        }

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

        // Update rewards
        if (gameData['rewards'] != null) {
          rewards.clear();
          final Map<String, dynamic> rewardsData = gameData['rewards'];
          for (var entry in rewardsData.entries) {
            if (entry.value['collected'] == true && entry.value['collectedBy'] == widget.userId) {
              rewards.add({
                'type': entry.value['type'],
                'position': entry.key,
              });
            }
          }
        }
      });
    });
  }

  void _showGameEndDialog(bool isWinner, String? reason) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(isWinner ? 'Tebrikler! Kazandın!' : 'Oyun Bitti'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isWinner
                  ? 'Puanın: $myScore\nRakip puanı: $opponentScore'
                  : 'Rakip kazandı.\nPuanın: $myScore\nRakip puanı: $opponentScore'),
              if (reason != null)
                Text('\nBitiş nedeni: ${_getEndReasonText(reason)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Ana menüye dön
              },
              child: const Text('Ana Menüye Dön'),
            ),
          ],
        ),
      );
    }
  }

  String _getEndReasonText(String reason) {
    switch (reason) {
      case 'surrender':
        return 'Teslim olma';
      case 'noLetters':
        return 'Harfler tükendi';
      case 'timeOut':
        return 'Süre doldu';
      case 'consecutivePasses':
        return 'Üst üste pas geçme';
      default:
        return 'Oyun tamamlandı';
    }
  }

  Future<void> _distributeInitialLetters() async {
    if (letterPoolFlat.isEmpty) return;

    // İlk 7 harfi al (havuzda daha az varsa mevcut sayıyı)
    final count = min(7, letterPoolFlat.length);
    final userLetters = letterPoolFlat.take(count).map((letter) {
      return {
        ...letter,
        "id": nextLetterId++, // Her harfe benzersiz bir ID ekliyoruz
      };
    }).toList();

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

  Future<void> _drawNewLetters(int count) async {
    if (letterPoolFlat.isEmpty) return;

    final drawCount = min(count, letterPoolFlat.length);
    if (drawCount <= 0) return;

    final newLetters = letterPoolFlat.take(drawCount).map((letter) {
      return {
        ...letter,
        "id": nextLetterId++, // Her harfe benzersiz bir ID ekliyoruz
      };
    }).toList();
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

  bool _isValidWordPlacement() {
    // Kontrol 1: En az bir harf yerleştirilmiş olmalı
    if (tempPlacedLetters.isEmpty) return false;

    // Kontrol 2: İlk hamle merkez hücreden (7,7) geçmeli
    bool isFirstMove = board.every((row) => row.every((cell) => cell.isEmpty));
    if (isFirstMove) {
      // İlk hamlede kelime merkez hücreden (7,7) geçmeli - bu kontrolü _confirmMove'a taşıdık
      // Sadece harflerin yatay veya dikey bir çizgide olmasını kontrol edelim
      bool isHorizontal = true;
      bool isVertical = true;
      int? commonRow, commonCol;

      List<String> positions = tempPlacedLetters.keys.toList();
      if (positions.length > 1) {
        List<int> firstParts = positions[0].split('-').map(int.parse).toList();
        commonRow = firstParts[0];
        commonCol = firstParts[1];

        for (int i = 1; i < positions.length; i++) {
          List<int> parts = positions[i].split('-').map(int.parse).toList();
          if (parts[0] != commonRow) isHorizontal = false;
          if (parts[1] != commonCol) isVertical = false;
        }

        if (!isHorizontal && !isVertical) return false;
      }

      return true;
    }

    // Kontrol 3.5: Yerleştirilen harfler tek doğrultuda olmalı
    if (tempPlacedLetters.length > 1) {
      bool isHorizontal = true;
      bool isVertical = true;

      List<String> positions = tempPlacedLetters.keys.toList();
      List<List<int>> coords = positions.map((p) => p.split('-').map(int.parse).toList()).toList();

      int firstRow = coords[0][0];
      int firstCol = coords[0][1];

      // Tüm harflerin aynı satır veya sütunda olup olmadığını kontrol et
      for (int i = 1; i < coords.length; i++) {
        if (coords[i][0] != firstRow) isHorizontal = false;
        if (coords[i][1] != firstCol) isVertical = false;
      }

      // Ne yatay ne dikey ise geçersiz yerleştirme
      if (!isHorizontal && !isVertical) return false;
    }


    // Kontrol 3: En az bir mevcut harfe bitişik olmalı (ilk hamle değilse)
    bool touchesExistingLetter = false;

    for (var position in tempPlacedLetters.keys) {
      final parts = position.split('-');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);

      // Yukarı, aşağı, sol, sağ hücreleri kontrol et
      final directions = [
        [row - 1, col], // yukarı
        [row + 1, col], // aşağı
        [row, col - 1], // sol
        [row, col + 1], // sağ
      ];

      for (var dir in directions) {
        int r = dir[0];
        int c = dir[1];

        if (r >= 0 && r < 15 && c >= 0 && c < 15) {
          // Tahtada yerleşik bir harfe dokunuyor mu?
          if (board[r][c].isNotEmpty) {
            touchesExistingLetter = true;
            break;
          }
        }
      }

      if (touchesExistingLetter) break;
    }

    if (!touchesExistingLetter) return false;

    // Kontrol 4: Yerleştirilen harfler ya yatay ya da dikey bir çizgide olmalı
    bool isHorizontal = true;
    bool isVertical = true;
    int? commonRow, commonCol;

    List<String> positions = tempPlacedLetters.keys.toList();
    if (positions.length > 1) {
      // İlk iki konum arasında yön belirle
      List<int> parts1 = positions[0].split('-').map(int.parse).toList();
      List<int> parts2 = positions[1].split('-').map(int.parse).toList();

      if (parts1[0] == parts2[0]) {
        // Yatay yerleştirme (aynı satır)
        isVertical = false;
        commonRow = parts1[0];
      } else if (parts1[1] == parts2[1]) {
        // Dikey yerleştirme (aynı sütun)
        isHorizontal = false;
        commonCol = parts1[1];
      } else {
        // Ne yatay ne dikey
        return false;
      }

      // Diğer tüm konumlar için yönü doğrula
      for (int i = 2; i < positions.length; i++) {
        List<int> parts = positions[i].split('-').map(int.parse).toList();

        if (isHorizontal && parts[0] != commonRow) return false;
        if (isVertical && parts[1] != commonCol) return false;
      }
    }

    // Kontrol 5: Yerleştirilen harfler birbirine bitişik olmalı (boşluk olmamalı)
    if (positions.length > 1) {
      // Pozisyonları sırala
      if (isHorizontal && commonRow != null) {
        // Sütun numaralarına göre sırala
        positions.sort((a, b) {
          int colA = int.parse(a.split('-')[1]);
          int colB = int.parse(b.split('-')[1]);
          return colA.compareTo(colB);
        });

        // Ardışık olduğunu kontrol et
        for (int i = 1; i < positions.length; i++) {
          int prevCol = int.parse(positions[i-1].split('-')[1]);
          int currCol = int.parse(positions[i].split('-')[1]);

          // Aradaki boşlukları kontrol et
          for (int col = prevCol + 1; col < currCol; col++) {
            // Boşluk tahtadaki bir harfle doldurulmuş mu?
            if (board[commonRow][col].isEmpty) {
              return false;
            }
          }
        }
      } else if (isVertical && commonCol != null) {
        // Satır numaralarına göre sırala
        positions.sort((a, b) {
          int rowA = int.parse(a.split('-')[0]);
          int rowB = int.parse(b.split('-')[0]);
          return rowA.compareTo(rowB);
        });

        // Ardışık olduğunu kontrol et
        for (int i = 1; i < positions.length; i++) {
          int prevRow = int.parse(positions[i-1].split('-')[0]);
          int currRow = int.parse(positions[i].split('-')[0]);

          // Aradaki boşlukları kontrol et
          for (int row = prevRow + 1; row < currRow; row++) {
            // Boşluk tahtadaki bir harfle doldurulmuş mu?
            if (board[row][commonCol].isEmpty) {
              return false;
            }
          }
        }
      }
    }

    // Kontrol 6: İlk hamle değilse, en az bir mevcut harfe bitişik olmalı
    if (!isFirstMove) {
      bool touchesExistingLetter = false;

      for (String position in positions) {
        List<int> parts = position.split('-').map(int.parse).toList();
        int row = parts[0];
        int col = parts[1];

        // Yukarı, aşağı, sol, sağ hücreleri kontrol et
        final directions = [
          [row - 1, col], // yukarı
          [row + 1, col], // aşağı
          [row, col - 1], // sol
          [row, col + 1], // sağ
        ];

        for (var dir in directions) {
          int r = dir[0];
          int c = dir[1];

          if (r >= 0 && r < 15 && c >= 0 && c < 15) {
            // Tahtada yerleşik bir harfe dokunuyor mu?
            if (board[r][c].isNotEmpty && !tempPlacedLetters.containsKey('$r-$c')) {
              touchesExistingLetter = true;
              break;
            }
          }
        }

        if (touchesExistingLetter) break;
      }

      if (!touchesExistingLetter) return false;
    }

    // Kontrol 6: Yerleştirilen harfler ve mevcut harflerle oluşturulan tüm kelimeler geçerli olmalı
    // Bu kontrolü _updateCurrentWord() içinde yapıyoruz

    // Tüm kontrolleri geçti
    return true;
  }

  void _updateCurrentWord() {
    if (tempPlacedLetters.isEmpty) {
      setState(() {
        currentWord = '';
        isWordValid = false;
        currentWordScore = 0;
      });
      return;
    }

    // Ana kelimeyi bulma
    List<String> positions = tempPlacedLetters.keys.toList();

    // Tüm harfler aynı satırda mı yoksa aynı sütunda mı kontrol et
    bool allSameRow = true;
    bool allSameCol = true;
    int? firstRow, firstCol;

    if (positions.isNotEmpty) {
      List<int> parts = positions[0].split('-').map(int.parse).toList();
      firstRow = parts[0];
      firstCol = parts[1];

      for (int i = 1; i < positions.length; i++) {
        List<int> currentParts = positions[i].split('-').map(int.parse).toList();
        if (currentParts[0] != firstRow) allSameRow = false;
        if (currentParts[1] != firstCol) allSameCol = false;
      }
    }

    bool isHorizontal = allSameRow && !allSameCol;
    bool isVertical = !allSameRow && allSameCol;

    // Tek bir harf yerleştirilmiş olabilir, yönü belirlemek için komşularına bakmalıyız
    if (positions.length == 1 && firstRow != null && firstCol != null) {
      bool hasHorizontalNeighbor = (firstCol! > 0 && board[firstRow!][firstCol! - 1].isNotEmpty) ||
          (firstCol! < 14 && board[firstRow!][firstCol! + 1].isNotEmpty);
      bool hasVerticalNeighbor = (firstRow! > 0 && board[firstRow! - 1][firstCol!].isNotEmpty) ||
          (firstRow! < 14 && board[firstRow! + 1][firstCol!].isNotEmpty);

      if (hasHorizontalNeighbor && !hasVerticalNeighbor) {
        isHorizontal = true;
        isVertical = false;
      } else if (!hasHorizontalNeighbor && hasVerticalNeighbor) {
        isHorizontal = false;
        isVertical = true;
      } else {
        // Varsayılan olarak yatay diyelim (aslında buraya gelmemesi lazım)
        isHorizontal = true;
        isVertical = false;
      }
    }

    // Ana kelimeyi oluştur ve kontrol et
    String mainWord = "";
    int totalScore = 0;
    bool wordValid = false;

    if (isHorizontal && firstRow != null) {
      // Yatay kelime için, en sol noktayı bul
      int minCol = firstCol!;
      while (minCol > 0 && (board[firstRow!][minCol - 1].isNotEmpty || tempPlacedLetters.containsKey('$firstRow-${minCol - 1}'))) {
        minCol--;
      }

      // Kelimeyi oluştur
      String word = "";
      for (int col = minCol; col < 15; col++) {
        String letter = "";
        if (tempPlacedLetters.containsKey('$firstRow-$col')) {
          letter = tempPlacedLetters['$firstRow-$col']!['char'];
        } else if (board[firstRow!][col].isNotEmpty) {
          letter = board[firstRow!][col];
        } else {
          break; // Kelime sona erdi
        }
        word += letter;
      }

      if (word.length > 1) {
        mainWord = word;
        wordValid = validWords.contains(word.toLowerCase());
        totalScore = _calculateWordScore(true, firstRow!, minCol, word.length);
      }
    } else if (isVertical && firstCol != null) {
      // Dikey kelime için, en üst noktayı bul
      int minRow = firstRow!;
      while (minRow > 0 && (board[minRow - 1][firstCol!].isNotEmpty || tempPlacedLetters.containsKey('${minRow - 1}-$firstCol'))) {
        minRow--;
      }

      // Kelimeyi oluştur
      String word = "";
      for (int row = minRow; row < 15; row++) {
        String letter = "";
        if (tempPlacedLetters.containsKey('$row-$firstCol')) {
          letter = tempPlacedLetters['$row-$firstCol']!['char'];
        } else if (board[row][firstCol!].isNotEmpty) {
          letter = board[row][firstCol!];
        } else {
          break; // Kelime sona erdi
        }
        word += letter;
      }

      if (word.length > 1) {
        mainWord = word;
        wordValid = validWords.contains(word.toLowerCase());
        totalScore = _calculateWordScore(false, minRow, firstCol!, word.length);
      }
    }

    setState(() {
      currentWord = mainWord;
      isWordValid = wordValid && mainWord.length > 1;
      currentWordScore = totalScore;
    });
  }

// Kelime puanını hesapla
  int _calculateWordScore(bool isHorizontal, int startRow, int startCol, int length) {
    int score = 0;
    int wordMultiplier = 1;

    for (int i = 0; i < length; i++) {
      int row = isHorizontal ? startRow : startRow + i;
      int col = isHorizontal ? startCol + i : startCol;

      // Sınırları kontrol et
      if (row >= 15 || col >= 15) break;

      // Harfin puanını al
      int letterPoint = 0;
      String posKey = '$row-$col';

      if (tempPlacedLetters.containsKey(posKey)) {
        letterPoint = tempPlacedLetters[posKey]!['point'] as int;
      } else if (board[row][col].isNotEmpty) {
        // Tahtadaki harfin puanını bulmak için _letterPool'dan arama yapabilirsiniz
        String letter = board[row][col];
        var letterInfo = _letterPool.firstWhere((l) => l['char'] == letter, orElse: () => {"point": 1});
        letterPoint = letterInfo['point'] as int;
      }

      int letterMultiplier = 1;

      // Özel hücreler için çarpanları uygula (sadece yeni yerleştirilen harfler için)
      if (tempPlacedLetters.containsKey(posKey)) {
        // Harfin 2 katı
        if ((row == 3 && (col == 0 || col == 7 || col == 14)) ||
            (row == 7 && (col == 3 || col == 11)) ||
            (row == 11 && (col == 0 || col == 7 || col == 14))) {
          letterMultiplier = 2;
        }
        // Harfin 3 katı
        else if ((row == 1 && (col == 5 || col == 9)) ||
            (row == 5 && (col == 1 || col == 5 || col == 9 || col == 13)) ||
            (row == 9 && (col == 1 || col == 5 || col == 9 || col == 13)) ||
            (row == 13 && (col == 5 || col == 9))) {
          letterMultiplier = 3;
        }
        // Kelimenin 2 katı
        else if ((row == 1 && (col == 1 || col == 13)) ||
            (row == 2 && (col == 2 || col == 12)) ||
            (row == 3 && (col == 3 || col == 11)) ||
            (row == 4 && (col == 4 || col == 10)) ||
            (row == 10 && (col == 4 || col == 10)) ||
            (row == 11 && (col == 3 || col == 11)) ||
            (row == 12 && (col == 2 || col == 12)) ||
            (row == 13 && (col == 1 || col == 13))) {
          wordMultiplier *= 2;
        }
        // Kelimenin 3 katı
        else if ((row == 0 && (col == 0 || col == 7 || col == 14)) ||
            (row == 7 && (col == 0 || col == 14)) ||
            (row == 14 && (col == 0 || col == 7 || col == 14))) {
          wordMultiplier *= 3;
        }
      }

      score += letterPoint * letterMultiplier;
    }

    // Kelime çarpanını uygula
    return score * wordMultiplier;
  }

  Future<void> _confirmMove() async {
    if (tempPlacedLetters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir kelime oluşturun")),
      );
      return;
    }

    // İlk hamle için özel kontrol
    bool isFirstMove = board.every((row) => row.every((cell) => cell.isEmpty));
    if (isFirstMove) {
      bool passesThroughCenter = tempPlacedLetters.containsKey('7-7');
      if (!passesThroughCenter) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlk hamle merkez hücreden (7,7) geçmelidir!")),
        );
        return;
      }
    }

    // Kelime yerleştirme kurallarını kontrol et
    if (!_isValidWordPlacement()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçersiz yerleştirme! Kelime tahtadaki harflere bağlı olmalı.")),
      );
      return;
    }

    // Kelime geçerli mi kontrol et
    _updateCurrentWord();
    if (!isWordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçersiz kelime! Türkçe kelime listesinde bulunamadı.")),
      );
      return;
    }

    try {
      // Kelimeyi oluşturan harfleri mayınlar açısından kontrol et
      int originalScore = currentWordScore;
      int finalScore = originalScore;
      bool transferPoints = false;
      bool cancelPoints = false;
      bool letterLoss = false;
      bool disableBonuses = false;

      // Mayın kontrolü
      for (var entry in tempPlacedLetters.entries) {
        if (mines.containsKey(entry.key) && mines[entry.key]!['triggered'] == false) {
          final mineType = mines[entry.key]!['type'];

          switch (mineType) {
            case 'pointDivision': // Puan Bölünmesi
              finalScore = (originalScore * 0.3).round();
              _showMineEffect("Puan Bölünmesi! Puanın %30'u alındı.");
              break;
            case 'pointTransfer': // Puan Transferi
              transferPoints = true;
              _showMineEffect("Puan Transferi! Puanın rakibe gitti.");
              break;
            case 'letterLoss': // Harf Kaybı
              letterLoss = true;
              _showMineEffect("Harf Kaybı! Elindeki harfler yenilenecek.");
              break;
            case 'bonusBlock': // Ekstra Hamle Engeli
              disableBonuses = true;
              if (originalScore != finalScore) {
                _showMineEffect("Ekstra Hamle Engeli! Bonus puanlar iptal edildi.");
              }
              break;
            case 'wordCancel': // Kelime İptali
              cancelPoints = true;
              _showMineEffect("Kelime İptali! Bu hamlenden puan alamazsın.");
              break;
          }

          // Mayını tetiklenmiş olarak işaretle
          mines[entry.key]!['triggered'] = true;

          // Mayını Firebase'de güncelle
          await FirebaseFirestore.instance
              .collection('games')
              .doc(widget.gameId)
              .update({
            "mines.${entry.key}.triggered": true
          });
        }
      }

      // Ödül kontrolü
      for (var entry in tempPlacedLetters.entries) {
        // Firebase'den rewards verilerini al
        final gameDoc = await FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .get();

        final Map<String, dynamic>? rewardsData = gameDoc.data()?['rewards'];

        if (rewardsData != null && rewardsData.containsKey(entry.key) &&
            rewardsData[entry.key]['collected'] == false) {

          // Ödülü toplandı olarak işaretle
          await FirebaseFirestore.instance
              .collection('games')
              .doc(widget.gameId)
              .update({
            "rewards.${entry.key}.collected": true,
            "rewards.${entry.key}.collectedBy": widget.userId,
          });

          final rewardType = rewardsData[entry.key]['type'];
          _showRewardCollected(rewardType);

          setState(() {
            rewards.add({
              'type': rewardType,
              'position': entry.key,
            });
          });
        }
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
      currentBoard.addAll(tempPlacedLetters);

      // Puanları hesapla
      if (cancelPoints) {
        finalScore = 0;
      }

      // Firebase güncellemelerini hazırla
      Map<String, dynamic> updates = {
        "board": currentBoard,
        "currentTurn": opponentId, // Sırayı rakibe geçir
        "lastAction": {
          "userId": widget.userId,
          "action": "move",
          "score": finalScore,
          "timestamp": FieldValue.serverTimestamp(),
        },
        "consecutivePassCount": 0, // Hamle yapıldı, pas sayacını sıfırla
      };

      // Puan güncellemeleri
      if (transferPoints) {
        updates["scores.$opponentId"] = FieldValue.increment(originalScore);
      } else if (!cancelPoints) {
        updates["scores.${widget.userId}"] = FieldValue.increment(finalScore);
      }

      // Firebase'i güncelle
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update(updates);

      // Kullanılan harfleri çıkar
      List<int> usedLetterIds = tempPlacedLetters.values.map((l) => l['id'] as int).toList();
      myLetters.removeWhere((l) => usedLetterIds.contains(l['id']));

      // Harf kaybı mayını tetiklendiyse
      if (letterLoss) {
        // Tüm harfleri havuza geri koy ve yeniden 7 harf al
        await _resetLetters();
      } else {
        // Eğer gerekliyse, yeni harfler çek
        if (myLetters.length < 7) {
          await _drawNewLetters(7 - myLetters.length);
        }
      }

      setState(() {
        // Onayladıktan sonra yerleştirilen harfleri kalıcı yap
        for (var entry in tempPlacedLetters.entries) {
          placedLetters[entry.key] = entry.value;
          final parts = entry.key.split('-');
          final row = int.parse(parts[0]);
          final col = int.parse(parts[1]);
          board[row][col] = entry.value['char'];
        }

        tempPlacedLetters = {}; // Geçici harfleri temizle
        currentWord = '';
        isWordValid = false;
        currentWordScore = 0;
        myTurn = false; // Sıranın geçtiğini kullanıcı arayüzünde güncelle
      });

      // Oyun sonu kontrolü
      if (myLetters.isEmpty && letterPoolFlat.isEmpty) {
        await _endGame('noLetters');
      }

      String message = "Hamle onaylandı!";
      if (finalScore > 0) {
        message += " $finalScore puan kazandın.";
      } else if (transferPoints) {
        message += " $originalScore puan rakibe transfer edildi.";
      } else if (cancelPoints) {
        message += " Puan iptal edildi.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hamle onaylanırken hata: $e")),
      );
    }
  }

  void _showMineEffect(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRewardCollected(String rewardType) {
    String message = "Ödül kazandın: ";

    switch (rewardType) {
      case 'areaRestriction':
        message += "Bölge Yasağı";
        break;
      case 'letterRestriction':
        message += "Harf Yasağı";
        break;
      case 'extraMove':
        message += "Ekstra Hamle Jokeri";
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.greenAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resetLetters() async {
    // Mevcut harfleri havuza geri koy
    for (var letter in myLetters) {
      letterPoolFlat.add({
        "char": letter['char'],
        "point": letter['point'],
      });
    }

    // Havuzu karıştır
    letterPoolFlat.shuffle(Random());

    // Harfleri temizle
    myLetters.clear();

    // Yeni 7 harf al
    await _drawNewLetters(7);
  }

  Future<void> _useReward(Map<String, dynamic> reward) async {
    final rewardType = reward['type'];

    switch (rewardType) {
      case 'areaRestriction':
        await _applyAreaRestriction();
        break;
      case 'letterRestriction':
        await _applyLetterRestriction();
        break;
      case 'extraMove':
        await _applyExtraMove();
        break;
    }

    // Ödülü kullanıldı olarak işaretle ve listeden kaldır
    setState(() {
      rewards.remove(reward);
    });
  }

  Future<void> _applyAreaRestriction() async {
    // Rastgele sağ veya sol tarafı seç
    final restrictedSide = Random().nextBool() ? 'left' : 'right';

    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "restrictions.areaRestriction": {
        "active": true,
        "side": restrictedSide,
        "appliedBy": widget.userId,
        "appliedTo": opponentId,
        "expiresAt": FieldValue.serverTimestamp(),
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bölge yasağı uygulandı! Rakip ${restrictedSide == 'left' ? 'sol' : 'sağ'} tarafa harf koyamayacak.")),
    );
  }

  Future<void> _applyLetterRestriction() async {
    // Opponent'ın mevcut harflerini al
    final gameDoc = await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .get();

    final opponentLetters = List<Map<String, dynamic>>.from(
        (gameDoc.data() as Map<String, dynamic>)['letters'][opponentId] ?? []);

    if (opponentLetters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rakibin elinde harf yok!")),
      );
      return;
    }

    // Rastgele 2 harf seç
    opponentLetters.shuffle(Random());
    final restrictedLetters = opponentLetters.take(min(2, opponentLetters.length)).toList();

    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "restrictions.letterRestriction": {
        "active": true,
        "letterIds": restrictedLetters.map((l) => l['id']).toList(),
        "appliedBy": widget.userId,
        "appliedTo": opponentId,
        "expiresAt": FieldValue.serverTimestamp(),
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Harf yasağı uygulandı! Rakip bir tur boyunca 2 harfini kullanamayacak.")),
    );
  }

  Future<void> _applyExtraMove() async {
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "extraMove": {
        "userId": widget.userId,
        "active": true,
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ekstra hamle hakkı kazandın! Bu turu tamamladıktan sonra bir hamle daha yapabileceksin.")),
    );
  }

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

      // Mevcut pas sayısını al
      int currentPassCount = (gameDoc.data() as Map<String, dynamic>)['consecutivePassCount'] ?? 0;
      int newPassCount = currentPassCount + 1;

      // Eğer arka arkaya 2 kez pas geçildiyse oyunu bitir
      if (newPassCount >= 2) {
        await _endGame('consecutivePasses');
        return;
      }

      // Sırayı rakibe geç ve pas bilgisini kaydet
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update({
        "currentTurn": opponentId,
        "consecutivePassCount": newPassCount,
        "lastAction": {
          "userId": widget.userId,
          "action": "pass",
          "timestamp": FieldValue.serverTimestamp(),
        }
      });

      // Kullanıcı arayüzünde sırayı güncelle
      setState(() {
        myTurn = false;
        consecutivePassCount = newPassCount;
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

  Future<void> _endGame(String reason) async {
    // Şu anki oyun verisini al
    DocumentSnapshot gameDoc = await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .get();

    final gameData = gameDoc.data() as Map<String, dynamic>;

    // Puanları al
    int myFinalScore = gameData['scores']?[widget.userId] ?? 0;
    int opponentFinalScore = gameData['scores']?[opponentId] ?? 0;

    // Eğer oyun harfler bittiği için bitiyorsa, kalan harflerin puanlarını hesapla
    if (reason == 'noLetters') {
      // Rakibin kalan harflerini al
      final opponentLetters = List<Map<String, dynamic>>.from(
          gameData['letters'][opponentId] ?? []);

      // Rakibin kalan harflerinin puanlarını topla
      int remainingPoints = 0;
      for (var letter in opponentLetters) {
        remainingPoints += letter['point'] as int;
      }

      // Bu puanları kullanıcıya ekle, rakipten düş
      myFinalScore += remainingPoints;
      opponentFinalScore -= remainingPoints;
    }

    // Kazananı belirle
    String winner;
    if (myFinalScore > opponentFinalScore) {
      winner = widget.userId;
    } else if (opponentFinalScore > myFinalScore) {
      winner = opponentId;
    } else {
      winner = 'draw'; // Beraberlik
    }

    // Oyun sonucu güncelle
    await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .update({
      "status": "completed",
      "endReason": reason,
      "endTime": FieldValue.serverTimestamp(),
      "winner": winner,
      "finalScores": {
        widget.userId: myFinalScore,
        opponentId: opponentFinalScore,
      }
    });

    // Oyun sonu dialogunu göster
    _showGameEndDialog(winner == widget.userId, reason);
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
          final placedChar = board[row][col];
          final tempChar = tempPlacedLetters['$row-$col']?['char'] ?? '';
          final displayChar = tempChar.isNotEmpty ? tempChar : placedChar;

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

          // If there's a permanent letter placed, change color to amber
          if (placedChar.isNotEmpty) {
            cellColor = Colors.amber;
          }

          // If there's a temporary letter placed, change color to light green or red based on validation
          if (tempChar.isNotEmpty) {
            cellColor = isWordValid ? Colors.lightGreen : Colors.red[300]!;
          }

          return DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) {
              // Eğer hücrede zaten bir harf varsa veya oyuncunun turnu değilse kabul etme
              if (!myTurn || displayChar.isNotEmpty) return false;

              // İlk hamle kontrolü
              bool isFirstMove = board.every((row) => row.every((cell) => cell.isEmpty));

              if (isFirstMove) {
                // İlk hamle için herhangi bir hücreye izin ver
                return true;
              } else {
                // İlk hamle değilse:
                if (tempPlacedLetters.isEmpty) {
                  // İlk harf mevcut tahtadaki harflere bitişik olmalı
                  bool touchesExistingLetter = false;

                  // Komşu hücreleri kontrol et
                  final directions = [
                    [row - 1, col], // yukarı
                    [row + 1, col], // aşağı
                    [row, col - 1], // sol
                    [row, col + 1]  // sağ
                  ];

                  for (var dir in directions) {
                    int r = dir[0];
                    int c = dir[1];

                    if (r >= 0 && r < 15 && c >= 0 && c < 15) {
                      if (board[r][c].isNotEmpty) {
                        touchesExistingLetter = true;
                        break;
                      }
                    }
                  }

                  return touchesExistingLetter;
                } else {
                  // Geçici yerleştirilen harfler varsa:
                  // 1. Geri kalan harfler için doğrultuyu belirle
                  List<String> positions = tempPlacedLetters.keys.toList();
                  bool isHorizontal = true;
                  bool isVertical = true;

                  if (positions.length > 1) {
                    // Yönü belirle
                    int firstRow = int.parse(positions[0].split('-')[0]);
                    int firstCol = int.parse(positions[0].split('-')[1]);

                    for (int i = 1; i < positions.length; i++) {
                      int currRow = int.parse(positions[i].split('-')[0]);
                      int currCol = int.parse(positions[i].split('-')[1]);

                      if (currRow != firstRow) isHorizontal = false;
                      if (currCol != firstCol) isVertical = false;
                    }
                  } else {
                    // Tek harf varsa, yönü belirlemek için mevcut tahtadaki harflere bak
                    int posRow = int.parse(positions[0].split('-')[0]);
                    int posCol = int.parse(positions[0].split('-')[1]);

                    // Solunda veya sağında harf var mı kontrol et
                    bool hasHorizontalNeighbor = (posCol > 0 && board[posRow][posCol-1].isNotEmpty) ||
                        (posCol < 14 && board[posRow][posCol+1].isNotEmpty);

                    // Üstünde veya altında harf var mı kontrol et
                    bool hasVerticalNeighbor = (posRow > 0 && board[posRow-1][posCol].isNotEmpty) ||
                        (posRow < 14 && board[posRow+1][posCol].isNotEmpty);

                    if (hasHorizontalNeighbor && !hasVerticalNeighbor) {
                      isHorizontal = true;
                      isVertical = false;
                    } else if (!hasHorizontalNeighbor && hasVerticalNeighbor) {
                      isHorizontal = false;
                      isVertical = true;
                    }
                  }

                  // 2. Yeni harf yerleştirilebilir mi kontrol et
                  if (isHorizontal) {
                    // Yatay kelime: aynı satırda olmalı
                    int commonRow = int.parse(positions[0].split('-')[0]);
                    return row == commonRow;
                  } else if (isVertical) {
                    // Dikey kelime: aynı sütunda olmalı
                    int commonCol = int.parse(positions[0].split('-')[1]);
                    return col == commonCol;
                  } else {
                    // Belirli bir yön yok, her iki yöne de izin ver
                    int firstRow = int.parse(positions[0].split('-')[0]);
                    int firstCol = int.parse(positions[0].split('-')[1]);
                    return row == firstRow || col == firstCol;
                  }
                }
              }
            },
            onAccept: (data) {
              if (!myTurn) return;

              setState(() {
                tempPlacedLetters['$row-$col'] = data;
                myLetters.removeWhere((l) => l['id'] == data['id']);
                _updateCurrentWord();
              });
            },
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTap: () {
                  if (myTurn && tempPlacedLetters.containsKey('$row-$col')) {
                    print("Removing letter from $row-$col"); // Debug için
                    setState(() {
                      final letter = tempPlacedLetters['$row-$col']!;
                      myLetters.add(letter);
                      tempPlacedLetters.remove('$row-$col');
                      _updateCurrentWord();
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          displayChar,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (tempChar.isNotEmpty)
                        Positioned(
                          bottom: 2,
                          right: 4,
                          child: Text(
                            (tempPlacedLetters['$row-$col']?['point'] ?? '').toString(),
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                    ],
                  ),
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
      child: Column(
        children: [
          if (currentWord.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isWordValid ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Kelime: $currentWord",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Puan: $currentWordScore",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: myLetters.map((letter) {
              return Draggable<Map<String, dynamic>>(
                data: letter,
                feedback: _buildLetterTile(letter),
                childWhenDragging: _buildLetterTile({"char": "", "point": 0}),
                child: _buildLetterTile(letter),
              );
            }).toList(),
          ),
          if (rewards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rewards.map((reward) {
                  return GestureDetector(
                    onTap: () => _useReward(reward),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _getRewardIcon(reward['type']),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'areaRestriction':
        return Icons.block;
      case 'letterRestriction':
        return Icons.text_fields;
      case 'extraMove':
        return Icons.add_circle;
      default:
        return Icons.star;
    }
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