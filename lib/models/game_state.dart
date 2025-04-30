// models/game_state.dart
import 'letter.dart';
import 'mine.dart';
import 'reward.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus {
  active,
  completed,
}

enum EndReason {
  surrender,
  noLetters,
  timeOut,
  consecutivePasses,
  completed,
}

class Restrictions {
  final AreaRestriction? areaRestriction;
  final LetterRestriction? letterRestriction;

  Restrictions({
    this.areaRestriction,
    this.letterRestriction,
  });

  // Map'ten Restrictions oluşturmak için factory constructor
  factory Restrictions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return Restrictions();

    return Restrictions(
      areaRestriction: map['areaRestriction'] != null
          ? AreaRestriction.fromMap(map['areaRestriction'])
          : null,
      letterRestriction: map['letterRestriction'] != null
          ? LetterRestriction.fromMap(map['letterRestriction'])
          : null,
    );
  }

  // Restrictions'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (areaRestriction != null) {
      map['areaRestriction'] = areaRestriction!.toMap();
    }
    if (letterRestriction != null) {
      map['letterRestriction'] = letterRestriction!.toMap();
    }
    return map;
  }
}

class AreaRestriction {
  final bool active;
  final String side; // 'left' veya 'right'
  final String appliedBy;
  final String appliedTo;
  final DateTime? expiresAt;

  AreaRestriction({
    required this.active,
    required this.side,
    required this.appliedBy,
    required this.appliedTo,
    this.expiresAt,
  });

  // Map'ten AreaRestriction oluşturmak için factory constructor
  factory AreaRestriction.fromMap(Map<String, dynamic> map) {
    // Timestamp verisini doğru şekilde işleme
    DateTime? expiresAt;
    if (map['expiresAt'] is Timestamp) {
      expiresAt = (map['expiresAt'] as Timestamp).toDate();
    } else if (map['expiresAt'] is String) {
      expiresAt = DateTime.parse(map['expiresAt']);
    }

    return AreaRestriction(
      active: map['active'] ?? false,
      side: map['side'] ?? 'right',
      appliedBy: map['appliedBy'] ?? '',
      appliedTo: map['appliedTo'] ?? '',
      expiresAt: expiresAt,
    );
  }

  // AreaRestriction'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'side': side,
      'appliedBy': appliedBy,
      'appliedTo': appliedTo,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class LetterRestriction {
  final bool active;
  final List<int> letterIds;
  final String appliedBy;
  final String appliedTo;
  final DateTime? expiresAt;

  LetterRestriction({
    required this.active,
    required this.letterIds,
    required this.appliedBy,
    required this.appliedTo,
    this.expiresAt,
  });

  // Map'ten LetterRestriction oluşturmak için factory constructor
  factory LetterRestriction.fromMap(Map<String, dynamic> map) {
    // Timestamp verisini doğru şekilde işleme
    DateTime? expiresAt;
    if (map['expiresAt'] is Timestamp) {
      expiresAt = (map['expiresAt'] as Timestamp).toDate();
    } else if (map['expiresAt'] is String) {
      expiresAt = DateTime.parse(map['expiresAt']);
    }

    return LetterRestriction(
      active: map['active'] ?? false,
      letterIds: List<int>.from(map['letterIds'] ?? []),
      appliedBy: map['appliedBy'] ?? '',
      appliedTo: map['appliedTo'] ?? '',
      expiresAt: expiresAt,
    );
  }

  // LetterRestriction'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'letterIds': letterIds,
      'appliedBy': appliedBy,
      'appliedTo': appliedTo,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class ExtraMove {
  final bool active;
  final String userId;

  ExtraMove({
    required this.active,
    required this.userId,
  });

  // Map'ten ExtraMove oluşturmak için factory constructor
  factory ExtraMove.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ExtraMove(active: false, userId: '');
    return ExtraMove(
      active: map['active'] ?? false,
      userId: map['userId'] ?? '',
    );
  }

  // ExtraMove'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'userId': userId,
    };
  }
}

class LastAction {
  final String userId;
  final String action; // 'move' veya 'pass'
  final int? score;
  final DateTime timestamp;

  LastAction({
    required this.userId,
    required this.action,
    this.score,
    required this.timestamp,
  });

  // Map'ten LastAction oluşturmak için factory constructor
  factory LastAction.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return LastAction(
        userId: '',
        action: '',
        timestamp: DateTime.now(),
      );
    }

    // Timestamp verisini doğru şekilde işleme
    DateTime timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      timestamp = DateTime.parse(map['timestamp']);
    } else {
      timestamp = DateTime.now();
    }

    return LastAction(
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      score: map['score'],
      timestamp: timestamp,
    );
  }

  // LastAction'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
    if (score != null) {
      map['score'] = score;
    }
    return map;
  }
}

class BoardCellModel {
  final String char;
  final int letterId;
  final int point;
  final String placedBy;

  BoardCellModel({
    required this.char,
    required this.letterId,
    required this.point,
    required this.placedBy,
  });

  // Map'ten BoardCellModel oluşturmak için factory constructor
  factory BoardCellModel.fromMap(Map<String, dynamic> map) {
    return BoardCellModel(
      char: map['char'] ?? '',
      letterId: map['id'] ?? 0,
      point: map['point'] ?? 0,
      placedBy: map['placedBy'] ?? '',
    );
  }

  // BoardCellModel'den Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'char': char,
      'id': letterId,
      'point': point,
      'placedBy': placedBy,
    };
  }
}

class GameState {
  final String gameId;
  final GameStatus status;
  final List<String> players;
  final String currentTurn;
  final Map<String, int> scores;
  final Map<String, List<Letter>> letters;
  final Map<String, BoardCellModel> board;
  final Map<String, Mine> mines;
  final Map<String, Reward> rewards;
  final List<Letter> letterPool;
  final int consecutivePassCount;
  final Restrictions restrictions;
  final ExtraMove extraMove;
  final LastAction lastAction;
  final String? winner;
  final EndReason? endReason;
  final DateTime? endTime;
  final Map<String, int>? finalScores;
  final int nextLetterId;

  GameState({
    required this.gameId,
    this.status = GameStatus.active,
    required this.players,
    required this.currentTurn,
    required this.scores,
    required this.letters,
    required this.board,
    required this.mines,
    required this.rewards,
    required this.letterPool,
    this.consecutivePassCount = 0,
    required this.restrictions,
    required this.extraMove,
    required this.lastAction,
    this.winner,
    this.endReason,
    this.endTime,
    this.finalScores,
    required this.nextLetterId,
  });

  // Map'ten GameState oluşturmak için factory constructor
  factory GameState.fromMap(String gameId, Map<String, dynamic> map) {
    // Oyuncu harflerini dönüştür
    final lettersMap = <String, List<Letter>>{};
    if (map['letters'] != null) {
      final letters = map['letters'] as Map<String, dynamic>;
      letters.forEach((playerId, playerLetters) {
        if (playerLetters is List) {
          lettersMap[playerId] = playerLetters
              .map((e) => Letter.fromMap(e))
              .toList();
        }
      });
    }

    // Tahta hücrelerini dönüştür
    final boardMap = <String, BoardCellModel>{};
    if (map['board'] != null) {
      final board = map['board'] as Map<String, dynamic>;
      board.forEach((position, cellData) {
        boardMap[position] = BoardCellModel.fromMap(cellData);
      });
    }

    // Mayınları dönüştür
    final minesMap = <String, Mine>{};
    if (map['mines'] != null) {
      final mines = map['mines'] as Map<String, dynamic>;
      mines.forEach((position, mineData) {
        minesMap[position] = Mine.fromMap(position, mineData);
      });
    }

    // Ödülleri dönüştür
    final rewardsMap = <String, Reward>{};
    if (map['rewards'] != null) {
      final rewards = map['rewards'] as Map<String, dynamic>;
      rewards.forEach((position, rewardData) {
        rewardsMap[position] = Reward.fromMap(position, rewardData);
      });
    }

    // Harf havuzunu dönüştür
    List<Letter> letterPool = [];
    if (map['letterPool'] != null) {
      letterPool = (map['letterPool'] as List).map((e) {
        final map = e as Map<String, dynamic>;
        return Letter(
          char: map['char'],
          point: map['point'],
          id: 0, // Havuzdaki harflerin ID'si yok
        );
      }).toList();
    }

    // Status, endReason gibi enum değerlerini dönüştür
    GameStatus status = GameStatus.active;
    if (map['status'] == 'completed') {
      status = GameStatus.completed;
    }

    EndReason? endReason;
    if (map['endReason'] != null) {
      switch (map['endReason']) {
        case 'surrender':
          endReason = EndReason.surrender;
          break;
        case 'noLetters':
          endReason = EndReason.noLetters;
          break;
        case 'timeOut':
          endReason = EndReason.timeOut;
          break;
        case 'consecutivePasses':
          endReason = EndReason.consecutivePasses;
          break;
        default:
          endReason = EndReason.completed;
      }
    }

    // Ek alanları dönüştür
    DateTime? endTime;
    if (map['endTime'] != null) {
      if (map['endTime'] is Timestamp) {
        endTime = (map['endTime'] as Timestamp).toDate();
      } else if (map['endTime'] is String) {
        endTime = DateTime.parse(map['endTime']);
      }
    }

    // Son işlem bilgisini dönüştür
    LastAction lastAction = LastAction.fromMap(map['lastAction']);

    // NextletterId'yi hesapla
    int maxId = 0;
    lettersMap.forEach((_, playerLetters) {
      for (var letter in playerLetters) {
        if (letter.id > maxId) {
          maxId = letter.id;
        }
      }
    });

    boardMap.forEach((_, cell) {
      if (cell.letterId > maxId) {
        maxId = cell.letterId;
      }
    });

    // finalScores alanını dönüştür
    Map<String, int>? finalScores;
    if (map['finalScores'] != null) {
      finalScores = Map<String, int>.from(map['finalScores']);
    }

    return GameState(
      gameId: gameId,
      status: status,
      players: List<String>.from(map['players'] ?? []),
      currentTurn: map['currentTurn'] ?? '',
      scores: Map<String, int>.from(map['scores'] ?? {}),
      letters: lettersMap,
      board: boardMap,
      mines: minesMap,
      rewards: rewardsMap,
      letterPool: letterPool,
      consecutivePassCount: map['consecutivePassCount'] ?? 0,
      restrictions: Restrictions.fromMap(map['restrictions']),
      extraMove: ExtraMove.fromMap(map['extraMove']),
      lastAction: lastAction,
      winner: map['winner'],
      endReason: endReason,
      endTime: endTime,
      finalScores: finalScores,
      nextLetterId: maxId + 1,
    );
  }

  // GameState'den Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    final lettersMap = <String, List<Map<String, dynamic>>>{};
    letters.forEach((playerId, playerLetters) {
      lettersMap[playerId] = playerLetters.map((e) => e.toMap()).toList();
    });

    final boardMap = <String, Map<String, dynamic>>{};
    board.forEach((position, cell) {
      boardMap[position] = cell.toMap();
    });

    final minesMap = <String, Map<String, dynamic>>{};
    mines.forEach((position, mine) {
      minesMap[position] = mine.toMap();
    });

    final rewardsMap = <String, Map<String, dynamic>>{};
    rewards.forEach((position, reward) {
      rewardsMap[position] = reward.toMap();
    });

    final letterPoolMap = letterPool.map((e) => {
      'char': e.char,
      'point': e.point,
    }).toList();

    final map = <String, dynamic>{
      'status': status == GameStatus.active ? 'active' : 'completed',
      'players': players,
      'currentTurn': currentTurn,
      'scores': scores,
      'letters': lettersMap,
      'board': boardMap,
      'mines': minesMap,
      'rewards': rewardsMap,
      'letterPool': letterPoolMap,
      'consecutivePassCount': consecutivePassCount,
      'restrictions': restrictions.toMap(),
      'extraMove': extraMove.toMap(),
      'lastAction': lastAction.toMap(),
    };

    if (winner != null) {
      map['winner'] = winner;
    }

    if (endReason != null) {
      String endReasonStr;
      switch (endReason!) {
        case EndReason.surrender:
          endReasonStr = 'surrender';
          break;
        case EndReason.noLetters:
          endReasonStr = 'noLetters';
          break;
        case EndReason.timeOut:
          endReasonStr = 'timeOut';
          break;
        case EndReason.consecutivePasses:
          endReasonStr = 'consecutivePasses';
          break;
        case EndReason.completed:
          endReasonStr = 'completed';
          break;
      }
      map['endReason'] = endReasonStr;
    }

    if (endTime != null) {
      map['endTime'] = endTime!.toIso8601String();
    }

    if (finalScores != null) {
      map['finalScores'] = finalScores;
    }

    return map;
  }

  // Oyunun bitip bitmediğini kontrol eden yardımcı metod
  bool get isGameEnded => status == GameStatus.completed;

  // Kopya oluşturma metodu
  GameState copyWith({
    String? gameId,
    GameStatus? status,
    List<String>? players,
    String? currentTurn,
    Map<String, int>? scores,
    Map<String, List<Letter>>? letters,
    Map<String, BoardCellModel>? board,
    Map<String, Mine>? mines,
    Map<String, Reward>? rewards,
    List<Letter>? letterPool,
    int? consecutivePassCount,
    Restrictions? restrictions,
    ExtraMove? extraMove,
    LastAction? lastAction,
    String? winner,
    EndReason? endReason,
    DateTime? endTime,
    Map<String, int>? finalScores,
    int? nextLetterId,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      status: status ?? this.status,
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      scores: scores ?? this.scores,
      letters: letters ?? this.letters,
      board: board ?? this.board,
      mines: mines ?? this.mines,
      rewards: rewards ?? this.rewards,
      letterPool: letterPool ?? this.letterPool,
      consecutivePassCount: consecutivePassCount ?? this.consecutivePassCount,
      restrictions: restrictions ?? this.restrictions,
      extraMove: extraMove ?? this.extraMove,
      lastAction: lastAction ?? this.lastAction,
      winner: winner ?? this.winner,
      endReason: endReason ?? this.endReason,
      endTime: endTime ?? this.endTime,
      finalScores: finalScores ?? this.finalScores,
      nextLetterId: nextLetterId ?? this.nextLetterId,
    );
  }
}