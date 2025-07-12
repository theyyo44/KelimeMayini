# Kelime Mayınları

Kelime Mayınları, Scrabble benzeri bir Türkçe kelime oyunudur. Oyuncular 15x15'lik bir tahtada harf döşeyerek Türkçe kelimeler oluştururken, mayınlardan kaçınmaya ve ödülleri toplamaya çalışırlar.

## 📱 Oyun Görselleri

### Ana Menü ve Giriş
![Ana Menü](screenshots/main_menu.png)
![Giriş Ekranı](screenshots/login_screen.png)

### Oyun Ekranı
![Oyun Tahtası](screenshots/game_board.png)
![Kelime Yerleştirme](screenshots/word_placement.png)

### Mayın ve Ödüller
![Mayın Efekti](screenshots/mine_effect.png)
![Ödül Toplama](screenshots/reward_collection.png)

### Oyun Sonu
![Oyun Sonu](screenshots/game_end.png)
![Sonuç Ekranı](screenshots/results_screen.png)

## ✨ Özellikler

- **🎮 Çok Oyunculu Gerçek Zamanlı Oyun**: Firebase ile senkronize edilmiş anlık multiplayer deneyimi
- **📚 Türkçe Kelime Sözlüğü**: Geniş Türkçe kelime veritabanı ile doğrulama
- **💣 Mayın Sistemi**: Tahtaya rastgele yerleştirilen mayınlar ile stratejik zorluk
- **🎁 Ödül Sistemi**: Oyunculara avantaj sağlayan güçlendirici ödüller
- **⭐ Özel Hücreler**: DLS, TLS, DWS, TWS hücreleri ile puan çarpanları
- **🚫 Kısıtlama Sistemi**: Rakibe uygulanan alan ve harf kısıtlamaları
- **🃏 Joker Harfler**: Herhangi bir harfi temsil edebilen özel taşlar

## 🎯 Oyun Mekanikleri

### 💣 Mayın Türleri
- **Puan Bölünmesi**: Elde edilen puanı %30'a düşürür
- **Puan Transferi**: Kazanılan puanları rakibe verir
- **Harf Kaybı**: Oyuncunun tüm harflerini sıfırlar
- **Bonus Engelleme**: Özel hücre bonuslarını iptal eder
- **Kelime İptali**: Kelimeden hiç puan alınmaz

### 🎁 Ödül Türleri
- **Bölge Yasağı**: Rakibin tahtanın bir yarısını kullanmasını engeller
- **Harf Yasağı**: Rakibin belirli harflerini bir tur kullanmasını engeller
- **Ekstra Hamle**: Oyuncuya ek bir hamle hakkı verir

## 🛠️ Teknolojiler

- **Flutter**: Cross-platform mobil uygulama geliştirme
- **Firebase Authentication**: Kullanıcı girişi ve kayıt
- **Cloud Firestore**: Gerçek zamanlı veritabanı ve oyun durumu senkronizasyonu
- **Google Fonts**: Özel tipografi
- **Flutter Animate**: UI animasyonları

## 🚀 Kurulum

1. Flutter SDK'yı yükleyin
2. Projeyi klonlayın
   ```bash
   git clone https://github.com/kullaniciadi/kelime_mayinlari.git
   ```
3. Proje dizinine gidin
   ```bash
   cd kelime_mayinlari
   ```
4. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
5. Firebase konfigürasyonunu tamamlayın
   - `android/app/google-services.json` dosyasını ekleyin
   - iOS için gerekli Firebase konfigürasyonunu yapın
6. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## 👨‍💻 Geliştirme

```bash
flutter analyze    # Kod analizi
flutter test      # Testleri çalıştır
flutter build apk # Android APK oluştur
flutter build ios # iOS build
```

## 📁 Proje Yapısı

```
lib/
├── models/          # Veri modelleri (GameState, Letter, Mine, Reward)
├── screens/         # UI ekranları
├── services/        # İş mantığı servisleri
├── utils/           # Yardımcı fonksiyonlar ve sabitler
└── widgets/         # Yeniden kullanılabilir UI bileşenleri
```

---

# Word Mines

Word Mines is a Turkish word game similar to Scrabble. Players place letters on a 15x15 board to form Turkish words while avoiding mines and collecting rewards.

## 📱 Game Screenshots

### Main Menu and Login
![Main Menu](screenshots/main_menu.png)
![Login Screen](screenshots/login_screen.png)

### Game Screen
![Game Board](screenshots/game_board.png)
![Word Placement](screenshots/word_placement.png)

### Mines and Rewards
![Mine Effect](screenshots/mine_effect.png)
![Reward Collection](screenshots/reward_collection.png)

### Game End
![Game End](screenshots/game_end.png)
![Results Screen](screenshots/results_screen.png)

## ✨ Features

- **🎮 Real-time Multiplayer**: Instant multiplayer experience synchronized with Firebase
- **📚 Turkish Word Dictionary**: Validation with comprehensive Turkish word database
- **💣 Mine System**: Strategic challenge with randomly placed mines on the board
- **🎁 Reward System**: Power-up rewards that give players advantages
- **⭐ Special Cells**: DLS, TLS, DWS, TWS cells with point multipliers
- **🚫 Restriction System**: Area and letter restrictions applied to opponents
- **🃏 Joker Letters**: Special tiles that can represent any letter

## 🎯 Game Mechanics

### 💣 Mine Types
- **Point Division**: Reduces earned points to 30%
- **Point Transfer**: Gives earned points to opponent
- **Letter Loss**: Resets all player's letters
- **Bonus Block**: Cancels special cell bonuses
- **Word Cancel**: No points earned from the word

### 🎁 Reward Types
- **Area Restriction**: Prevents opponent from using half of the board
- **Letter Restriction**: Prevents opponent from using specific letters for one turn
- **Extra Move**: Gives player an additional move

## 🛠️ Technologies

- **Flutter**: Cross-platform mobile app development
- **Firebase Authentication**: User login and registration
- **Cloud Firestore**: Real-time database and game state synchronization
- **Google Fonts**: Custom typography
- **Flutter Animate**: UI animations

## 🚀 Installation

1. Install Flutter SDK
2. Clone the project
   ```bash
   git clone https://github.com/username/kelime_mayinlari.git
   ```
3. Navigate to project directory
   ```bash
   cd kelime_mayinlari
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Complete Firebase configuration
   - Add `android/app/google-services.json` file
   - Set up Firebase configuration for iOS
6. Run the app:
   ```bash
   flutter run
   ```

## 👨‍💻 Development

```bash
flutter analyze    # Code analysis
flutter test      # Run tests
flutter build apk # Build Android APK
flutter build ios # Build iOS
```

## 📁 Project Structure

```
lib/
├── models/          # Data models (GameState, Letter, Mine, Reward)
├── screens/         # UI screens
├── services/        # Business logic services
├── utils/           # Helper functions and constants
└── widgets/         # Reusable UI components
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
