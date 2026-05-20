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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çamaşırhane Giriş")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "E-posta"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Şifre"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 1. Giriş Yap
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  // 2. Log Kaydını Realtime Database'e Gönder
                  final DatabaseReference ref = FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                  ).ref("logs");

                  await ref.push().set({
                    'kullanici': emailController.text.trim(),
                    'islem': 'Sisteme giriş yaptı',
                    'tarih': ServerValue.timestamp,
                  }).then((_) {
                    print("VERI FIREBASE'E GITTI!");
                  });

                } catch (e) {
                  // Log yazarken hata oluşsa bile konsola yaz, uygulamayı kilitleme
                  debugPrint("Log Hatasi: $e");
                }

                // 3. Her durumda Ana Sayfaya Geçiş
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giriş Başarılı!')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: const Text("Giriş Yap"),
            ),
            const SizedBox(height: 10),
            // Kayıt ol butonu senin istediğin gibi tam buraya eklendi
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text("Hesabın yok mu? Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}