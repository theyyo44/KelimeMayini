// models/reward.dart
enum RewardType {
  areaRestriction,    // Bölge Yasağı
  letterRestriction,  // Harf Yasağı
  extraMove,          // Ekstra Hamle Jokeri
}

class Reward {
  final String position; // "row-col" formatında konum
  final RewardType type;
  final bool collected;
  final bool used;
  final String? collectedBy;

  Reward({
    required this.position,
    required this.type,
    this.collected = false,
    this.used = false,
    this.collectedBy,
  });

  // Map'ten Reward oluşturmak için factory constructor
  factory Reward.fromMap(String position, Map<String, dynamic> map) {
    return Reward(
      position: position,
      type: _typeFromString(map['type']),
      collected: map['collected'] ?? false,
      used: map['used'] ?? false,
      collectedBy: map['collectedBy'],
    );
  }

  // String'den RewardType oluşturmak için yardımcı metod
  static RewardType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'areaRestriction':
        return RewardType.areaRestriction;
      case 'letterRestriction':
        return RewardType.letterRestriction;
      case 'extraMove':
        return RewardType.extraMove;
      default:
        throw ArgumentError('Bilinmeyen ödül tipi: $typeStr');
    }
  }

  // RewardType'tan String'e dönüştürmek için yardımcı metod
  static String typeToString(RewardType type) {
    switch (type) {
      case RewardType.areaRestriction:
        return 'areaRestriction';
      case RewardType.letterRestriction:
        return 'letterRestriction';
      case RewardType.extraMove:
        return 'extraMove';
    }
  }

  // Reward'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'type': typeToString(type),
      'collected': collected,
      'used': used,
      'collectedBy': collectedBy,
    };
  }

  // Reward'ı toplanmış olarak işaretleyen metod
  Reward collect(String userId) {
    return Reward(
      position: position,
      type: type,
      collected: true,
      used: used,
      collectedBy: userId,
    );
  }

  // Reward'ı kullanılmış olarak işaretleyen metod
  Reward use() {
    return Reward(
      position: position,
      type: type,
      collected: collected,
      used: true,
      collectedBy: collectedBy,
    );
  }

  // Ödül açıklamasını getiren yardımcı metod
  String getDescription() {
    switch (type) {
      case RewardType.areaRestriction:
        return "Bölge Yasağı: Rakip belirli bir bölgeye harf koyamaz";
      case RewardType.letterRestriction:
        return "Harf Yasağı: Rakibin 2 harfi 1 tur boyunca donar";
      case RewardType.extraMove:
        return "Ekstra Hamle: Bu turdan sonra bir hamle daha yapabilirsin";
    }
  }
}