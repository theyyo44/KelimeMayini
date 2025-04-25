import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kelime_mayinlari/screens/login_screen.dart';
import 'screens/register_screen.dart'; // kayıt ekranını import et
import 'screens/auth_landing_screen.dart';
import 'package:kelime_mayinlari/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase'i başlat
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthLandingScreen(), // Kullanıcı giriş yaptı mı kontrolü burda
    );
  }
}
