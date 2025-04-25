import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Stack(
        children: [
          // Arka planda dönen harfler
          for (var i = 0; i < 15; i++)
            Positioned(
              top: (screenSize.height / 15) * (i % 5),
              left: (screenSize.width / 10) * (i % 6),
              child: Text(
                String.fromCharCode(65 + i), // A, B, C, ...
                style: TextStyle(
                  fontSize: 60,
                  color: Colors.white.withOpacity(0.05),
                  fontWeight: FontWeight.bold,
                ),
              ).animate(delay: Duration(milliseconds: i * 200)).moveY(begin: -30, end: 30).fadeIn(),
            ),

          // Asıl içerik
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Kelime Mayınları",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: -1, end: 0),

                  const SizedBox(height: 24),

                  Text(
                    "Harflerini seç, mayınları patlat!",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 50),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
                  ).animate(delay: 600.ms).fadeIn().slideY(begin: 1, end: 0),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Kayıt Ol", style: TextStyle(fontSize: 18)),
                  ).animate(delay: 700.ms).fadeIn().slideY(begin: 1, end: 0),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
