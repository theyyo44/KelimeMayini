// models/letter.dart
class Letter {
  final String char;
  final int point;
  final int id;
  final bool isJoker;

  Letter({
    required this.char,
    required this.point,
    required this.id,
    this.isJoker = false,
  });

  // Map'ten Letter oluşturmak için factory constructor
  factory Letter.fromMap(Map<String, dynamic> map) {
    return Letter(
      char: map['char'] ?? '',
      point: map['point'] ?? 0,
      id: map['id'] ?? 0,
      isJoker: map['isJoker'] ?? (map['char'] == 'JOKER'),
    );
  }

  // Letter'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'char': char,
      'point': point,
      'id': id,
      'isJoker': isJoker,
    };
  }

  // Kopyalama metodu
  Letter copyWith({
    String? char,
    int? point,
    int? id,
    bool? isJoker,
  }) {
    return Letter(
      char: char ?? this.char,
      point: point ?? this.point,
      id: id ?? this.id,
      isJoker: isJoker ?? this.isJoker,
    );
  }
}