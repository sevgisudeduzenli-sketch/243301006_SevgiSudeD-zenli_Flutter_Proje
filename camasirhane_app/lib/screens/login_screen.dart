import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // HATA ÇÖZÜLDÜ: Değişkeni late yapıp riske girmek yerine burada doğrudan tanımlıyoruz
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    // Animasyonu burada güvenli bir şekilde başlatıp döngüye alıyoruz
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. KATMAN: Animasyonlu Baloncuk Arka Planı
          if (_animationController != null)
            AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return CustomPaint(
                  painter: BubblePainter(_animationController!.value),
                  child: Container(),
                );
              },
            ),
          
          // 2. KATMAN: Giriş Formu
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.waves, size: 80, color: Colors.blue),
                  const SizedBox(height: 10),
                  const Text(
                    "Akıllı Çamaşırhane",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const Text("Kampüs Sipariş & Takip Sistemi", style: TextStyle(color: Colors.blueGrey)),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text("Oturum Aç", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "E-posta",
                              prefixIcon: const Icon(Icons.email, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.blue.shade50.withOpacity(0.5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Şifre",
                              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.blue.shade50.withOpacity(0.5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                );
                                if (!mounted) return;
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giriş Hatalı!')));
                              }
                            },
                            child: const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    child: const Text("Hesabın yok mu? Kayıt Ol", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final double animationValue;
  BubblePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.1);
    final random = Random(42); 

    for (int i = 0; i < 15; i++) {
      double x = random.nextDouble() * size.width;
      double y = ((random.nextDouble() * size.height) - (animationValue * size.height)) % size.height;
      double radius = random.nextDouble() * 40 + 10;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}