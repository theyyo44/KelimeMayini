import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final user = await _authService.loginWithEmail(email, password);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } else {
      setState(() {
        _errorMessage = "Giriş başarısız. Lütfen bilgilerinizi kontrol edin.";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Hesabınıza Giriş Yapın",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "E-posta",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
