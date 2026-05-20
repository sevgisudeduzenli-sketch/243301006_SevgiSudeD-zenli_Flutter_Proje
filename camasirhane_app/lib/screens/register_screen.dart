import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Eksik olan buydu, şimdi eklendi!
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  String secilenRol = 'Öğrenci'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çamaşırhane Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Ekran küçük gelirse taşma hatası vermesin diye korumaya aldık
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
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                value: secilenRol,
                decoration: const InputDecoration(labelText: "Kullanıcı Tipi / Rol"),
                items: const [
                  DropdownMenuItem(value: 'Öğrenci', child: Text('Öğrenci (Standart Kullanıcı)')),
                  DropdownMenuItem(value: 'Yönetici', child: Text('Yönetici (Admin)')),
                ],
                onChanged: (yeniDeger) {
                  setState(() {
                    secilenRol = yeniDeger!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // 1. Firebase Auth ile kayıt oluşturuluyor
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
  
                    String uid = userCredential.user!.uid;
  
                    // 2. Kullanıcı rolünü veritabanına kaydediyoruz
                    final DatabaseReference userRef = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                    ).ref("kullanicilar/$uid");
  
                    await userRef.set({
                      'email': emailController.text.trim(),
                      'rol': secilenRol,
                    });
  
                    // 3. Log kaydı oluşturuluyor
                    final DatabaseReference logRef = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                    ).ref("logs");
  
                    await logRef.push().set({
                      'kullanici': emailController.text.trim(),
                      'islem': 'Yeni hesap oluşturdu ($secilenRol)',
                      'tarih': ServerValue.timestamp,
                    });
  
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kayıt Başarılı ve Log Eklendi!')),
                    );
                    
                    // Doğrudan ana sayfaya yönlendiriyoruz
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
  
                  } on FirebaseAuthException catch (e) {
                    String mesaj = 'Bir hata oluştu';
                    if (e.code == 'weak-password') {
                      mesaj = 'Şifre çok zayıf!';
                    } else if (e.code == 'email-already-in-use') {
                      mesaj = 'Bu e-posta adresi zaten kullanımda!';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(mesaj)),
                    );
                  } catch (hata) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $hata')),
                    );
                  }
                },
                child: const Text("Kayıt Ol ve Giriş Yap"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}