import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _loading = false;

  final List<String> _yetkiliYneticiler = [
    "sevgisude@email.com", 
    "aysenur@email.com"    
  ];

  void _girisYap() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text.trim(), 
              password: _sifreController.text.trim()
          );

      User? user = userCredential.user;
      if (user != null) {
        String girisYapanEmail = user.email?.toLowerCase().trim() ?? "";

        final ref = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com'
        ).ref();

        if (_yetkiliYneticiler.contains(girisYapanEmail)) {
          await ref.child("kullanicilar/${user.uid}").update({'rol': 'Personel'});
        } else {
          final snapshot = await ref.child("kullanicilar/${user.uid}/rol").get();
          if (!snapshot.exists) {
            await ref.child("kullanicilar/${user.uid}").update({'rol': 'Öğrenci'});
          }
        }

        await ref.child("log_kayitlari").push().set({
          'kullaniciId': user.uid,
          'email': girisYapanEmail,
          'islem': 'Sisteme Başarılı Giriş Yapıldı',
          'zaman': ServerValue.timestamp
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giriş Başarısız: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sadece şık ve statik gradyan arka plan (Sıfır işlemci yükü, sıfır donma!)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.grey.shade900], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_laundry_service, size: 80, color: Colors.blue.shade300),
                          const SizedBox(height: 10),
                          const Text("Çamaşırhane", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          const Text("Akıllı Yönetim Sistemi", style: TextStyle(color: Colors.white60, fontSize: 14)),
                          const SizedBox(height: 50),
                          
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDekorasyonu("E-posta Adresi", Icons.email),
                            validator: (v) => v!.isEmpty ? "E-posta gerekli" : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _sifreController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDekorasyonu("Şifre", Icons.lock),
                            validator: (v) => v!.isEmpty ? "Şifre gerekli" : null,
                          ),
                          const SizedBox(height: 30),
                          
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55), 
                              backgroundColor: Colors.blue.shade700, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            onPressed: _girisYap,
                            child: const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                            },
                            child: const Text("Henüz hesabın yok mu? Kayıt Ol", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  InputDecoration _inputDekorasyonu(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.blue.shade400),
      filled: true,
      fillColor: Colors.white.withAlpha(20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}