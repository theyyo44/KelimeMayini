// models/mine.dart
enum MineType {
  pointDivision,   // Puan Bölünmesi
  pointTransfer,   // Puan Transferi
  letterLoss,      // Harf Kaybı
  bonusBlock,      // Ekstra Hamle Engeli
  wordCancel,      // Kelime İptali
}

class Mine {
  final String position; // "row-col" formatında konum
  final MineType type;
  final bool triggered;

  Mine({
    required this.position,
    required this.type,
    this.triggered = false,
  });

  // Map'ten Mine oluşturmak için factory constructor
  factory Mine.fromMap(String position, Map<String, dynamic> map) {
    return Mine(
      position: position,
      type: _typeFromString(map['type']),
      triggered: map['triggered'] ?? false,
    );
  }

  // String'den MineType oluşturmak için yardımcı metod
  static MineType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'pointDivision':
        return MineType.pointDivision;
      case 'pointTransfer':
        return MineType.pointTransfer;
      case 'letterLoss':
        return MineType.letterLoss;
      case 'bonusBlock':
        return MineType.bonusBlock;
      case 'wordCancel':
        return MineType.wordCancel;
      default:
        throw ArgumentError('Bilinmeyen mayın tipi: $typeStr');
    }
  }

  // MineType'tan String'e dönüştürmek için yardımcı metod
  static String typeToString(MineType type) {
    switch (type) {
      case MineType.pointDivision:
        return 'pointDivision';
      case MineType.pointTransfer:
        return 'pointTransfer';
      case MineType.letterLoss:
        return 'letterLoss';
      case MineType.bonusBlock:
        return 'bonusBlock';
      case MineType.wordCancel:
        return 'wordCancel';
    }
  }

  // Mine'dan Map oluşturmak için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'type': typeToString(type),
      'triggered': triggered,
    };
  }

  // Mine'ı tetiklenmiş olarak işaretleyen metod
  Mine trigger() {
    return Mine(
      position: position,
      type: type,
      triggered: true,
    );
  }
}