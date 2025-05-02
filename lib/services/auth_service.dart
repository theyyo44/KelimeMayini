import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Kayıt işlemi (e-posta, şifre ve kullanıcı adı ile)
  Future<User?> registerWithEmail(String email, String username, String password) async {
    try {
      // Kullanıcı adı benzersiz mi kontrol et
      final existingUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception("Bu kullanıcı adı zaten kullanılıyor.");
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'username': username,
        'email': email,
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

  // 🔑 Kullanıcı adı ve şifre ile giriş
  Future<User?> loginWithUsername(String username, String password) async {
    try {
      // Kullanıcı adına göre e-posta bul
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Kullanıcı bulunamadı.");
      }

      final email = querySnapshot.docs.first['email'];

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

  Future<void> logout() async => await _auth.signOut();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userChanges => _auth.authStateChanges();
}
