import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _loading = false;

  void _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(), 
              password: _sifreController.text.trim()
          );

      User? user = userCredential.user;

      if (user != null) {
        final ref = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com'
        ).ref();

        await ref.child("kullanicilar").child(user.uid).set({
          'adSoyad': _adController.text.trim(), 
          'email': _emailController.text.trim().toLowerCase(),
          'telefon': _telController.text.trim(), 
          'rol': 'Öğrenci', 
        });

        await ref.child("log_kayitlari").push().set({
          'kullaniciId': user.uid,
          'email': _emailController.text.trim().toLowerCase(),
          'islem': 'Yeni Hesap Başarıyla Kullanıcılara ve Veritabanına Eklendi (Ad: ${_adController.text.trim()})',
          'zaman': ServerValue.timestamp
        });

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text("Kayıt Başarılı", style: TextStyle(color: Colors.white)),
            content: const Text("Bilgileriniz Çamaşırhane Uygulamaları sistemine başarıyla işlendi. Şimdi giriş yapabilirsiniz.", style: TextStyle(color: Colors.white70)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context); 
                },
                child: const Text("Tamam"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veritabanı Kayıt Hatası: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Yeni Hesap Oluştur"), 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        foregroundColor: Colors.white
      ),
      body: Stack(
        children: [
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
            : Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0), 
                  child: Form(
                    key: _formKey,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Icon(Icons.local_laundry_service, size: 80, color: Colors.blue.shade300),
                            const SizedBox(height: 10),
                            const Text("Kayıt Merkezi", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            const Text("Akıllı Yönetim Sistemi", style: TextStyle(color: Colors.white60, fontSize: 14)),
                            const SizedBox(height: 40),
                            _inputAlani("Ad Soyad", _adController, Icons.person, false),
                            const SizedBox(height: 15),
                            _inputAlani("E-posta Adresi", _emailController, Icons.email, false),
                            const SizedBox(height: 15),
                            _inputAlani("Telefon Numarası", _telController, Icons.phone, false),
                            const SizedBox(height: 15),
                            _inputAlani("Şifre", _sifreController, Icons.lock, true),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(55), 
                                backgroundColor: Colors.blue.shade700, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                              ),
                              onPressed: _kayitOl,
                              child: const Text("Kayıt Ol ve Hesap Aç", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _inputAlani(String label, TextEditingController controller, IconData icon, bool obscure) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.blue.shade400),
        filled: true,
        fillColor: Colors.white.withAlpha(20), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? "Bu alan boş bırakılamaz" : null,
    );
  }
}