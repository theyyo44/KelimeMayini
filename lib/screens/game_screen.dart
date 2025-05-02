// screens/game_screen.dart
import 'dart:async';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Models
import '../models/letter.dart';
import '../models/mine.dart';
import '../models/reward.dart';
import '../models/game_state.dart';

// Services
import '../services/firebase_service.dart';
import '../services/letter_service.dart';
import '../services/game_logic_service.dart';

// Utils
import '../utils/constants.dart';
import '../utils/turkish_helper.dart';
import '../utils/validators.dart';

// Widgets
import '../widgets/board_cell.dart';
import '../widgets/letter_tile.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/rewards_bar.dart';
import '../widgets/game_actions.dart';

// Dialogs
import 'dialogs/game_end_dialog.dart';
import 'dialogs/surrender_dialog.dart';
import 'dialogs/restriction_dialog.dart';


class GameScreen extends StatefulWidget {
  final String gameId;
  final String userId;



  const GameScreen({super.key, required this.gameId, required this.userId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Services
  late FirebaseService _firebaseService;
  late LetterService _letterService;
  late GameLogicService _gameLogicService;
  String myUsername = "";
  String opponentUsername = "";
  String opponentId = "";

  // Game state
  bool isLoading = true;
  GameState? gameState;

  // Local state for board and letters
  List<List<String>> board = List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, ''));
  List<Letter> myLetters = [];
  Map<String, Map<String, dynamic>> placedLetters = {};
  Map<String, Map<String, dynamic>> tempPlacedLetters = {}; // Geçici yerleştirilen harfler

  // Word validation
  bool isWordValid = false;
  String currentWord = '';
  int currentWordScore = 0;
  List<Map<String, dynamic>> allWords = []; // Çoklu kelime kontrolü için

  // Area restrictions
  bool hasAreaRestriction = false;
  String restrictedSide = '';

  // Letter restrictions
  List<int> restrictedLetterIds = [];

  // Mayın ve Ödüller
  Map<String, Mine> mines = {};
  Map<String, Reward> rewards = {};
  Map<String, bool> mineVisibility = {}; // Hangi mayınların görünür olduğu
  Map<String, bool> rewardVisibility = {}; // Hangi ödüllerin görünür olduğu

  bool _isAreaRestrictionNotified = false;
  bool _isLetterRestrictionNotified = false;

  Timer? _gameTimer;
  int _remainingSeconds = 0;

  // Add the transformation controller for zooming
  late TransformationController _boardTransformController;


  @override
  void initState() {
    super.initState();

    _boardTransformController = TransformationController();
    _initializeServices();
    _loadWordList();
    _loadGameData().then((_) {
      _loadUsernames();
      _setupGameTimer();
    });
  }



  @override
  void dispose() {
    // Dispose the controller when the widget is destroyed
    _gameTimer?.cancel();
    _boardTransformController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _firebaseService = FirebaseService();
    _letterService = LetterService(_firebaseService);
    _gameLogicService = GameLogicService(_firebaseService, _letterService);
  }

  // Timer kurulumu için yeni metod
  void _setupGameTimer() {

    _gameTimer?.cancel();
    if (gameState == null) return;

    final createdAtTimestamp = gameState!.createdAt;
    final durationSeconds = gameState!.duration;

    if (createdAtTimestamp == null || durationSeconds == null) {
      print("Zaman bilgisi bulunamadı, timer kurulmadı");
      return;
    }

    DateTime startTime = createdAtTimestamp;
    if (gameState!.lastAction != null && gameState!.lastAction!.timestamp != null) {
      startTime = gameState!.lastAction!.timestamp!;
    }
    // Şimdiki zaman ile oluşturulma zamanı arasındaki farkı hesapla
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inSeconds;

    // Kalan süreyi hesapla
    _remainingSeconds = durationSeconds - elapsed;
    if (_remainingSeconds < -5) _remainingSeconds = 0;
    print("Kalan süre: $_remainingSeconds saniye");

    // Süre zaten bitmişse oyunu sonlandır
    if (_remainingSeconds <= 0) {
      _handleTimeOut();
      return;
    }

    // Timer'ı başlat
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      // Her 10 saniyede bir debug için yazdır
      if (_remainingSeconds % 10 == 0) {
        print("Kalan süre: $_remainingSeconds saniye");
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

// Süre bitiminde çağrılacak metod
  void _handleTimeOut() {
    print("Süre doldu! Oyun sonlandırılıyor...");

    // Eğer oyun zaten bitmişse işlem yapma
    if (gameState?.status == GameStatus.completed) {
      print("Oyun zaten tamamlanmış durumda, işlem yapılmadı");
      return;
    }

    // Kullanıcının sırası değilse kazanan olarak işaretle
    // Kullanıcının sırasıysa kaybeden olarak işaretle
    final winnerId = _isMyTurn() ? opponentId : widget.userId;

    // Bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Süre doldu! Oyun sona erdi."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );

    // Oyunu bitir
    _gameLogicService.endGame(
        widget.gameId,
        widget.userId,
        opponentId,
        'timeOut',
        winnerId
    ).then((_) {
      print("Oyun süre bitimi nedeniyle sonlandırıldı.");
    }).catchError((e) {
      print("Oyun sonlandırılırken hata: $e");
    });
  }

  Future<void> _loadUsernames() async {
    final firebaseService = FirebaseService();
    myUsername = await firebaseService.getUsernameById(widget.userId);
    opponentUsername = await firebaseService.getUsernameById(opponentId);
    setState(() {});
  }

  Future<void> _loadWordList() async {
    await TurkishHelper.loadWordList();
  }

  Future<void> _loadGameData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load game state
      gameState = await _firebaseService.loadGameState(widget.gameId);

      // Get opponent ID
      opponentId = gameState!.players.firstWhere(
            (id) => id != widget.userId,
        orElse: () => '',
      );

      // Oyunun ilk başlangıcında harfler yoksa dağıt
      if ((gameState!.letters.isEmpty || gameState!.letterPool.isEmpty) && gameState!.board.isEmpty) {
        print("Harfler henüz dağıtılmamış, dağıtılıyor...");
        await _letterService.initializeGameLetters(widget.gameId);

        // Güncel oyun durumunu tekrar yükle
        gameState = await _firebaseService.loadGameState(widget.gameId);
        print("Harfler dağıtıldıktan sonra oyun durumu yeniden yüklendi");
      }
      // Mayın ve ödülleri kontrol et ve gerekirse yerleştir
      await _setupMinesAndRewards();

      // Initialize board state from game state
      _initializeBoardFromGameState();

      // Initialize letters
      _initializeLettersFromGameState();

      // Check for restrictions
      _checkRestrictions();

      // Set letter service state - Sadece nextLetterId'yi ayarla, harf havuzunu değil
      _letterService.setNextLetterId(gameState!.nextLetterId);

      // Setup real-time listener
      _setupGameListener();
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

  void _initializeBoardFromGameState() {
    // Clear current board
    board = List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, ''));
    placedLetters = {};

    // Load board state from game state
    gameState!.board.forEach((position, cell) {
      final coords = position.split('-');
      final row = int.parse(coords[0]);
      final col = int.parse(coords[1]);

      board[row][col] = cell.char;
      placedLetters[position] = {
        'char': cell.char,
        'id': cell.letterId,
        'point': cell.point,
        'placedBy': cell.placedBy,
      };
    });
  }

  void _initializeLettersFromGameState() {
    // Get current user's letters
    myLetters = gameState!.letters[widget.userId] ?? [];

    // If user has no letters, distribute initial letters
    if (myLetters.isEmpty) {
      _distributeInitialLetters();
    }
  }

  void _checkRestrictions() {
    final restrictions = gameState!.restrictions;

    // Area restriction
    if (restrictions.areaRestriction != null &&
        restrictions.areaRestriction!.active &&
        restrictions.areaRestriction!.appliedTo == widget.userId) {
      setState(() {
        hasAreaRestriction = true;
        restrictedSide = restrictions.areaRestriction!.side;
      });
      if (!_isAreaRestrictionNotified) {
        _isAreaRestrictionNotified = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Dikkat! ${restrictedSide == 'left' ? 'Sol' : 'Sağ'} tarafa harf koyamazsın!"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      setState(() {
        hasAreaRestriction = false;
        restrictedSide = '';
        _isAreaRestrictionNotified = false;
      });
    }

    // Letter restriction
    if (restrictions.letterRestriction != null &&
        restrictions.letterRestriction!.active &&
        restrictions.letterRestriction!.appliedTo == widget.userId) {
      setState(() {
        restrictedLetterIds = restrictions.letterRestriction!.letterIds;
      });
      // Debug bilgisi
      print("Bu oyuncu için harf kısıtlaması aktif. Kısıtlanan harf ID'leri: $restrictedLetterIds");
      // Eğer bu bir yeni kısıtlama ise, kullanıcıya bilgi ver
      if (!_isLetterRestrictionNotified) {
        _isLetterRestrictionNotified = true;

        // Kısıtlanan harfleri bul
        List<String> restrictedChars = myLetters
            .where((letter) => restrictedLetterIds.contains(letter.id))
            .map((letter) => letter.char)
            .toList();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Dikkat! ${restrictedChars.join(', ')} harflerin bu tur için kısıtlandı!"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      setState(() {
        restrictedLetterIds = [];
        _isLetterRestrictionNotified = false;
      });
    }
  }

  void _setupGameListener() {
    _firebaseService.gameStateStream(widget.gameId).listen((updatedGameState) {
      if (mounted) {
        final previousRestrictions = gameState?.restrictions;

        setState(() {
          // Update game state
          gameState = updatedGameState;

          // Check for game end
          if (gameState!.status == GameStatus.completed && !_isDialogShowing) {
            _showGameEndDialog();
          }
          // Update letters if they've changed
          if (gameState!.letters.containsKey(widget.userId)) {
            myLetters = gameState!.letters[widget.userId] ?? [];
          }

          // Update board state with new letters only
          gameState!.board.forEach((position, cell) {
            if (!placedLetters.containsKey(position)) {
              final coords = position.split('-');
              final row = int.parse(coords[0]);
              final col = int.parse(coords[1]);

              board[row][col] = cell.char;
              placedLetters[position] = {
                'char': cell.char,
                'id': cell.letterId,
                'point': cell.point,
                'placedBy': cell.placedBy,
              };
            }
          });

          _updateMineAndRewardVisibility();

          _letterService.setNextLetterId(gameState!.nextLetterId);
          // Check for restrictions
          _setupGameTimer();

          // Debug için kalan harf sayısını yazdır
          print("Firebase'den gelen harf sayısı: ${gameState!.letterPool.length}");
        });
        _checkRestrictions();

        _checkForNewRestrictions(previousRestrictions);
      }
    });
  }
  void _checkForNewRestrictions(Restrictions? previousRestrictions) {
    if (previousRestrictions == null || gameState == null) return;

    // Bölge kısıtlaması kontrolü
    final currentAreaRestriction = gameState!.restrictions.areaRestriction;
    final previousAreaRestriction = previousRestrictions.areaRestriction;

    if (currentAreaRestriction != null &&
        currentAreaRestriction.active &&
        currentAreaRestriction.appliedTo == widget.userId) {

      // Yeni gelmiş bir kısıtlama mı?
      bool isNewRestriction = previousAreaRestriction == null ||
          !previousAreaRestriction.active ||
          previousAreaRestriction.appliedTo != widget.userId;

      if (isNewRestriction) {
        // Diyalog göster
        RestrictionDialog.show(
          context: context,
          restrictionType: 'area',
          side: currentAreaRestriction.side,
        );
      }
    }

    // Harf kısıtlaması kontrolü
    final currentLetterRestriction = gameState!.restrictions.letterRestriction;
    final previousLetterRestriction = previousRestrictions.letterRestriction;

    if (currentLetterRestriction != null &&
        currentLetterRestriction.active &&
        currentLetterRestriction.appliedTo == widget.userId) {

      // Yeni gelmiş bir kısıtlama mı?
      bool isNewRestriction = previousLetterRestriction == null ||
          !previousLetterRestriction.active ||
          previousLetterRestriction.appliedTo != widget.userId;

      if (isNewRestriction) {
        // Kısıtlanan harfleri bul
        List<String> restrictedChars = myLetters
            .where((letter) => currentLetterRestriction.letterIds.contains(letter.id))
            .map((letter) => letter.char)
            .toList();

        // Diyalog göster
        RestrictionDialog.show(
          context: context,
          restrictionType: 'letter',
          restrictedLetters: restrictedChars,
        );
      }
    }
  }


  bool _isDialogShowing = false;

  void _showGameEndDialog() {
    _isDialogShowing = true;

    // Determine if user is winner
    bool isWinner = gameState!.winner == widget.userId;
    int myScore = gameState!.scores[widget.userId] ?? 0;
    int opponentScore = gameState!.scores[opponentId] ?? 0;

    // Show game end dialog
    GameEndDialog.show(
      context: context,
      isWinner: isWinner,
      endReason: gameState!.endReason,
      myScore: myScore,
      opponentScore: opponentScore,
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  Future<void> _distributeInitialLetters() async {
    try {
      myLetters = await _letterService.distributeInitialLetters(widget.gameId, widget.userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harfler dağıtılırken hata: $e")),
      );
    }
  }

  void _updateCurrentWord() {
    // Validation logic moved to the GameValidator class
    if (tempPlacedLetters.isEmpty) {
      setState(() {
        currentWord = '';
        isWordValid = false;
        currentWordScore = 0;
        allWords = [];
      });
      return;
    }

    // Get word info from validator
    Map<String, dynamic> wordInfo = GameValidator.getWordInfo(board, tempPlacedLetters);

    setState(() {
      currentWord = wordInfo['word'];
      isWordValid = wordInfo['isValid'];
      currentWordScore = wordInfo['score'];

      // Çoklu kelime kontrolü - allWords listesini güncelleme
      allWords = List<Map<String, dynamic>>.from(wordInfo['allWords'] ?? []);

      // Debug: Oluşturulan tüm kelimeleri göster
      if (allWords.isNotEmpty) {
        String formattedWords = allWords.map((w) =>
        "${w['word']} (${w['score']} puan, ${w['isValid'] ? 'geçerli' : 'geçersiz'})").join(", ");
        print("Oluşturulan tüm kelimeler: $formattedWords");
      }
    });
  }

  /// Mayın ve ödülleri kontrol et ve gerekirse yerleştir
  /// Mayın ve ödülleri kontrol et ve gerekirse yerleştir
  Future<void> _setupMinesAndRewards() async {
    try {
      print("=== Mayın ve Ödül Kurulumu Başlıyor ===");

      // Güncel oyun durumunu al
      var currentGameState = await _firebaseService.loadGameState(widget.gameId);

      // İlk olarak mayınları kontrol et
      if (currentGameState.mines.isEmpty) {
        print("Mayınlar oluşturulacak...");

        // Mayınları yerleştir
        // MINE_TYPES sabitinden mayın tiplerini ve sayılarını al
        Random random = Random();
        Map<String, Map<String, dynamic>> newMines = {};
        Set<String> positions = {};

        for (var mineType in MINE_TYPES) {
          String type = mineType['type'];
          int count = mineType['count'];

          print("Yerleştiriliyor: $count adet $type mayını");

          for (int i = 0; i < count; i++) {
            String position;
            int newRow, newCol;

            // Benzersiz ve merkez olmayan bir konum seç
            do {
              newRow = random.nextInt(BOARD_SIZE);
              newCol = random.nextInt(BOARD_SIZE);
              position = '$newRow-$newCol';
            } while (positions.contains(position) || (newRow == 7 && newCol == 7));

            positions.add(position);
            newMines[position] = {
              'type': type,
              'triggered': false,
            };

            print("Mayın yerleştirildi: $type -> $position");

            // Her mayını Firebase'e ekle
            try {
              await _firebaseService.updateMineStatus(
                  widget.gameId,
                  position,
                  false,
                  mineType: type
              );
            } catch (e) {
              print("Mayın kaydederken hata: $e");
            }
          }
        }

        print("Toplam ${newMines.length} mayın Firebase'e kaydedildi");

        // Oyun durumunu yeniden yükle
        currentGameState = await _firebaseService.loadGameState(widget.gameId);
      } else {
        print("Mevcut mayın sayısı: ${currentGameState.mines.length}");
      }

      // Ödülleri kontrol et
      if (currentGameState.rewards.isEmpty) {
        print("Ödüller oluşturulacak...");

        // Ödülleri yerleştir
        // REWARD_TYPES sabitinden ödül tiplerini ve sayılarını al
        Random random = Random();
        Map<String, Map<String, dynamic>> newRewards = {};
        Set<String> positions = {};

        for (var rewardType in REWARD_TYPES) {
          String type = rewardType['type'];
          int count = rewardType['count'];

          print("Yerleştiriliyor: $count adet $type ödülü");

          for (int i = 0; i < count; i++) {
            String position;
            int newRow, newCol;

            // Benzersiz, merkez olmayan ve mayın olmayan bir konum seç
            do {
              newRow = random.nextInt(BOARD_SIZE);
              newCol = random.nextInt(BOARD_SIZE);
              position = '$newRow-$newCol';
            } while (
            positions.contains(position) ||
                (newRow == 7 && newCol == 7) ||
                currentGameState.mines.containsKey(position)
            );

            positions.add(position);
            newRewards[position] = {
              'type': type,
              'collected': false,
            };

            print("Ödül yerleştirildi: $type -> $position");

            // Her ödülü Firebase'e ekle
            try {
              await _firebaseService.updateRewardStatus(
                  widget.gameId,
                  position,
                  false, // collected
                  null, // collectedBy
                  false, // used
                  rewardType: type
              );
            } catch (e) {
              print("Ödül kaydederken hata: $e");
            }
          }
        }

        print("Toplam ${newRewards.length} ödül Firebase'e kaydedildi");

        // Oyun durumunu yeniden yükle
        currentGameState = await _firebaseService.loadGameState(widget.gameId);
      } else {
        print("Mevcut ödül sayısı: ${currentGameState.rewards.length}");
      }

      // Görüntüleme ayarlarını güncelle
      setState(() {
        // Mayınları güncelle
        mines = currentGameState.mines;

        // Ödülleri güncelle
        rewards = currentGameState.rewards;

        // Görünürlükleri güncelle
        _updateMineAndRewardVisibility();
      });

      print("=== Mayın ve Ödül Kurulumu Tamamlandı ===");
      print("Güncel Mayın Sayısı: ${mines.length}");
      print("Güncel Ödül Sayısı: ${rewards.length}");

    } catch (e) {
      print("!!! Mayın ve ödül kurulumu hatası: $e");
    }
  }

  /// Mayın ve ödül görünürlüklerini günceller
  void _updateMineAndRewardVisibility() {
    print("Mayın ve ödül görünürlükleri güncelleniyor...");

    // Görünürlükleri sıfırla
    Map<String, bool> newMineVisibility = {};
    Map<String, bool> newRewardVisibility = {};

    // Sadece kendi turunda ve tetiklenmemiş mayınlar görünür olsun
    if (_isMyTurn()) {
      // Mayınları kontrol et
      if (mines.isNotEmpty) {
        mines.forEach((position, mine) {
          // Tahtada bu pozisyonda harf yoksa ve mayın tetiklenmemişse göster
          final coords = position.split('-');
          if (coords.length == 2) {
            int row = int.parse(coords[0]);
            int col = int.parse(coords[1]);

            if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
              if (board[row][col].isEmpty && !mine.triggered) {
                newMineVisibility[position] = true;
              }
            }
          }
        });
      }

      // Ödülleri kontrol et
      if (rewards.isNotEmpty) {
        rewards.forEach((position, reward) {
          // Tahtada bu pozisyonda harf yoksa ve ödül toplanmamışsa göster
          final coords = position.split('-');
          if (coords.length == 2) {
            int row = int.parse(coords[0]);
            int col = int.parse(coords[1]);

            if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
              if (board[row][col].isEmpty && !reward.collected) {
                newRewardVisibility[position] = true;
              }
            }
          }
        });
      }
    }

    setState(() {
      mineVisibility = newMineVisibility;
      rewardVisibility = newRewardVisibility;
    });

    print("Görünür mayın sayısı: ${newMineVisibility.length}");
    print("Görünür ödül sayısı: ${newRewardVisibility.length}");
  }


  Future<void> _confirmMove() async {
    if (tempPlacedLetters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir kelime oluşturun")),
      );
      return;
    }

    // Validate placement
    Map<String, dynamic> validationResult = _gameLogicService.validatePlacement(
      board: board,
      placedLetters: placedLetters,
      tempPlacedLetters: tempPlacedLetters,
      hasAreaRestriction: hasAreaRestriction,
      restrictedSide: restrictedSide,
    );

    if (!validationResult['isValid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationResult['error'] ?? "Geçersiz yerleştirme!")),
      );
      return;
    }

    if (!isWordValid) {
      // Eğer tüm kelimeler kontrolünden geçemediyse
      if (allWords.isNotEmpty) {
        // Geçersiz kelimeler varsa, bunları göster
        List<String> invalidWords = allWords
            .where((w) => w['isValid'] == false)
            .map((w) => w['word'] as String)
            .toList();

        if (invalidWords.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Geçersiz kelimeler: ${invalidWords.join(', ')}")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Geçersiz kelime yerleştirmesi!")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Geçerli bir kelime oluşturun!")),
        );
      }
      return;
    }

    try {
      print("=== Hamle Onaylama Başlıyor ===");

      // Convert temp letters to actual Letter objects
      Map<String, Letter> actualTempLetters = {};
      for (var entry in tempPlacedLetters.entries) {
        actualTempLetters[entry.key] = Letter(
          char: entry.value['char'],
          point: entry.value['point'],
          id: entry.value['id'],
        );
      }

      // Confirm move
      Map<String, dynamic> result = await _gameLogicService.confirmMove(
        gameId: widget.gameId,
        userId: widget.userId,
        opponentId: opponentId,
        board: board,
        placedLetters: placedLetters,
        tempPlacedLetters: tempPlacedLetters,
        myLetters: myLetters,
        mines: mines, // Mayın bilgilerini geçir
      );

      if (result['success']) {
        print("Hamle onaylandı, sonuçlar işleniyor...");

        // Mayın etkileri varsa göster
        if (result['triggeredMines'] != null && (result['triggeredMines'] as List).isNotEmpty) {
          List<Map<String, dynamic>> triggeredMines = List<Map<String, dynamic>>.from(result['triggeredMines']);

          for (var mineInfo in triggeredMines) {
            String mineType = mineInfo['type'];
            String message = "Mayın Tetiklendi! ";

            switch (mineType) {
              case 'pointDivision':
                message += "Puan Bölünmesi! Puanın %30'u alındı.";
                break;
              case 'pointTransfer':
                message += "Puan Transferi! Puanın rakibe gitti.";
                break;
              case 'letterLoss':
                message += "Harf Kaybı! Elindeki harfler yenilenecek.";
                break;
              case 'bonusBlock':
                message += "Ekstra Hamle Engeli! Bonus puanlar iptal edildi.";
                break;
              case 'wordCancel':
                message += "Kelime İptali! Bu hamlenden puan alamazsın.";
                break;
              default:
                message += "Bilinmeyen mayın etkisi!";
            }

            _showMineEffect(message);
            print("Mayın etkisi gösterildi: $message");
          }
        }

        // Ödül toplanması varsa göster
        if (result['collectedRewards'] != null && (result['collectedRewards'] as List).isNotEmpty) {
          List<Map<String, dynamic>> collectedRewards = List<Map<String, dynamic>>.from(result['collectedRewards']);

          for (var rewardInfo in collectedRewards) {
            String rewardType = rewardInfo['type'];
            _showRewardCollected(rewardType);
            print("Ödül toplama gösterildi: $rewardType");
          }
        }

        // Show appropriate messages based on result
        String message = "Hamle onaylandı!";
        if (result['score'] > 0) {
          message += " ${result['score']} puan kazandın.";
        } else if (result['transferPoints']) {
          message += " ${result['word']} puan rakibe transfer edildi.";
        } else if (result['cancelPoints']) {
          message += " Puan iptal edildi.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        print("Kullanıcıya bilgi gösterildi: $message");

        setState(() {
          // Update the board with confirmed letters
          for (var entry in tempPlacedLetters.entries) {
            placedLetters[entry.key] = entry.value;
            final parts = entry.key.split('-');
            final row = int.parse(parts[0]);
            final col = int.parse(parts[1]);
            board[row][col] = entry.value['char'];
          }

          // Clear temporary letters
          tempPlacedLetters = {};
          currentWord = '';
          isWordValid = false;
          currentWordScore = 0;
          allWords = [];

          // Update letters
          myLetters = result['updatedLetters'];

          // Kalan harf sayısını güncelle
          print("Hamle sonrası kalan harf sayısı: ${gameState?.letterPool.length ?? 0}");

          // Mayın ve ödül görünürlüklerini güncelle
          print("Görünürlükler güncelleniyor...");
          _updateMineAndRewardVisibility();
        });

        print("=== Hamle Onaylama Tamamlandı ===");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? "Hamle onaylanırken hata oluştu.")),
        );
        print("Hamle onaylama hatası: ${result['error']}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hamle onaylanırken hata: $e")),
      );
      print("Hamle onaylama istisna hatası: $e");
    }
  }

  /// Mayın Etkisini Göster
  void _showMineEffect(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );

    // Ekstra görsel geri bildirim ekle
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text("Mayın Tetiklendi!"),
        content: Text(message),
        backgroundColor: Colors.red[100],
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  /// Ödül Toplandı Bildirimi
  void _showRewardCollected(String rewardType) {
    String message = "Ödül kazandın: ";
    String detail = "";

    switch (rewardType) {
      case 'areaRestriction':
        message += "Bölge Yasağı";
        detail = "Rakibin belirli bir bölgeye harf koymasını engelleyebilirsin!";
        break;
      case 'letterRestriction':
        message += "Harf Yasağı";
        detail = "Rakibin elindeki bazı harfleri dondurabilirsin!";
        break;
      case 'extraMove':
        message += "Ekstra Hamle Jokeri";
        detail = "Sıran geldiğinde ekstra bir hamle yapabilirsin!";
        break;
      default:
        message += "Bilinmeyen Ödül";
        detail = "Bu ödülü RewardsBar'dan kullanabilirsin!";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.greenAccent,
        duration: const Duration(seconds: 3),
      ),
    );

    // Ekstra görsel geri bildirim ekle
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text("Ödül Kazandın!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(detail),
            const SizedBox(height: 16),
            const Text("Ödülü kullanmak için alt barda görünen ödül ikonuna tıklayabilirsin.",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green[100],
        icon: const Icon(Icons.star, color: Colors.amber, size: 40),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  Future<void> _passTurn() async {
    if (!_isMyTurn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şu anda senin sıran değil!")),
      );
      return;
    }

    try {
      bool gameEnded = await _gameLogicService.passTurn(
        widget.gameId,
        widget.userId,
        opponentId,
        gameState!.consecutivePassCount,
      );

      if (!gameEnded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pas geçildi, sıra rakibe geçti.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pas geçilirken hata: $e")),
      );
    }
  }

  Future<void> _surrender() async {
    final confirmed = await SurrenderDialog.show(context);

    if (confirmed == true) {
      try {
        await _gameLogicService.surrender(widget.gameId, widget.userId, opponentId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oyun teslim olarak sona erdi.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Teslim olurken hata: $e")),
        );
      }
    }
  }

  Future<void> _useReward(Reward reward) async {
    try {
      bool success = await _gameLogicService.useReward(
        widget.gameId,
        widget.userId,
        opponentId,
        reward,
      );

      if (success) {
        String message;
        switch (reward.type) {
          case RewardType.areaRestriction:

            final updatedGameState = await _firebaseService.loadGameState(widget.gameId);
            final restrictedSide = updatedGameState.restrictions.areaRestriction?.side ?? 'right';

            message = "Bölge yasağı uygulandı! Rakip bir tarafa harf koyamayacak.";
            break;
          case RewardType.letterRestriction:
            message = "Harf yasağı uygulandı! Rakibin bazı harfleri donduruldu.";
            break;
          case RewardType.extraMove:
            message = "Ekstra hamle hakkı kazandın! Bu turu tamamladıktan sonra bir hamle daha yapabileceksin.";
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ödül kullanılamadı."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödül kullanılırken hata: $e")),
      );
    }
  }

  bool _isMyTurn() {
    if (gameState == null) return false;

    // Normal turn check
    bool myTurn = gameState!.currentTurn == widget.userId;

    // Check for extra move
    if (!myTurn &&
        gameState!.extraMove.active &&
        gameState!.extraMove.userId == widget.userId) {
      print("Extra move is active for the current user");
      myTurn = true;
    }

    return myTurn;
  }

  bool _isLetterRestricted(int letterId) {
    return restrictedLetterIds.contains(letterId);
  }
  Widget _buildBoard() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double boardWidth = constraints.maxWidth;
          final double boardHeight = constraints.maxHeight;

          return Container(
            width: boardWidth,
            height: boardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const ScrollPhysics(), // Normal kaydırma davranışı
              padding: const EdgeInsets.all(6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: BOARD_SIZE,
                childAspectRatio: 1.0,
              ),
              itemCount: BOARD_SIZE * BOARD_SIZE,
              itemBuilder: (context, index) {
                final row = index ~/ BOARD_SIZE;
                final col = index % BOARD_SIZE;
                final placedChar = board[row][col];
                final tempChar = tempPlacedLetters['$row-$col']?['char'] ?? '';
                final displayChar = tempChar.isNotEmpty ? tempChar : placedChar;
                final point = tempPlacedLetters['$row-$col']?['point'];

                final position = '$row-$col';
                final hasMine = mineVisibility[position] ?? false;
                final hasReward = rewardVisibility[position] ?? false;

                return BoardCell(
                  row: row,
                  col: col,
                  displayChar: displayChar,
                  point: displayChar.isNotEmpty ? point : null,
                  isTemporary: tempChar.isNotEmpty,
                  isWordValid: isWordValid,
                  myTurn: _isMyTurn(),
                  hasAreaRestriction: hasAreaRestriction,
                  restrictedSide: restrictedSide,
                  hasMine: hasMine,
                  hasReward: hasReward,
                  onAccept: (data) {
                    setState(() {
                      tempPlacedLetters['$row-$col'] = data;
                      myLetters.removeWhere((l) => l.id == data['id']);
                      _updateCurrentWord();
                    });
                  },
                  onTap: () {
                    if (_isMyTurn() && tempPlacedLetters.containsKey('$row-$col')) {
                      setState(() {
                        final letter = tempPlacedLetters['$row-$col']!;
                        myLetters.add(Letter.fromMap(letter));
                        tempPlacedLetters.remove('$row-$col');
                        _updateCurrentWord();
                      });
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLetters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.indigo[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Letters row with animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey<int>(myLetters.length), // Forces animation when letters change
              mainAxisAlignment: MainAxisAlignment.center,
              children: myLetters.map((letter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: LetterTile(
                    letter: letter,
                    isActive: _isMyTurn(),
                    isRestricted: _isLetterRestricted(letter.id),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Rewards bar with animation
          if (gameState != null)
            RewardsBar(
              rewards: gameState!.rewards.values
                  .where((r) => r.collected && r.collectedBy == widget.userId && !r.used)
                  .toList(),
              myTurn: _isMyTurn(),
              onUseReward: _useReward,
            ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading || gameState == null) {
      return Scaffold(
        backgroundColor: GameStyles.secondaryColor,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Firebase'den alınan harf havuzu boyutunu kullan
    final remainingLetterCount = gameState!.letterPool.length;

    return Scaffold(
      backgroundColor: GameStyles.secondaryColor,
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
          // Top bar with scores and turn info
          GameTopBar(
            myScore: gameState!.scores[widget.userId] ?? 0,
            opponentScore: gameState!.scores[opponentId] ?? 0,
            remainingLettersCount: remainingLetterCount,
            myTurn: _isMyTurn(),
            myUsername: myUsername,
            opponentUsername: opponentUsername,
            remainingSeconds: _remainingSeconds,
          ),

          const SizedBox(height: 8),

          // Game board
          _buildBoard(),

          const SizedBox(height: 50),

          // Letters area
          _buildLetters(),

          // Game actions
          GameActions(
            myTurn: _isMyTurn(),
            isWordValid: isWordValid,
            currentWord: currentWord,
            currentWordScore: currentWordScore,
            allWords: allWords,
            onConfirm: _confirmMove,
            onPass: _passTurn,
            onSurrender: _surrender,
          ),
        ],
      ),
    );
  }
}