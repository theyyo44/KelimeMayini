import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 Kayıt işlemi (e-posta ve şifre ile)
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🆕 Yeni kullanıcı için başlangıç verilerini kaydet
      await _firestore.collection('users').doc(result.user!.uid).set({
        'username': email.split('@')[0], // e-posta başı
        'wins': 0,
        'matches': 0,
        'points': 0,
      });

      return result.user;
    } catch (e) {
      print("Kayıt hatası: $e");
      return null;
    }
  }

  // 🔑 Giriş işlemi
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Giriş hatası: $e");
      return null;
    }
  }

  //  Oturumu kapatma
  Future<void> logout() async {
    await _auth.signOut();
  }

  //  Şu anki kullanıcı
  User? get currentUser => _auth.currentUser;

  //  Giriş durumunu dinleme (isteğe bağlı)
  Stream<User?> get userChanges => _auth.authStateChanges();
}
