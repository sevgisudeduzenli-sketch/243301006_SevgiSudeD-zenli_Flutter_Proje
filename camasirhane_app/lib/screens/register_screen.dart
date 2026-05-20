import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();
  final TextEditingController telefonController = TextEditingController();
  
  String secilenRol = 'Öğrenci'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çamaşırhane Kayıt Ol"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( 
          child: Column(
            children: [
              TextField(
                controller: adController,
                decoration: const InputDecoration(labelText: "Adınız", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: soyadController,
                decoration: const InputDecoration(labelText: "Soyadınız", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telefonController,
                decoration: const InputDecoration(labelText: "Telefon Numaranız", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                value: secilenRol,
                decoration: const InputDecoration(labelText: "Kullanıcı Tipi / Rol", border: OutlineInputBorder()),
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
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                ),
                onPressed: () async {
                  if (adController.text.isEmpty || soyadController.text.isEmpty || telefonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
                    );
                    return;
                  }

                  try {
                    // 1. Firebase Auth ile kayıt oluşturuluyor
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
  
                    String uid = userCredential.user!.uid;
  
                    // 2. Genişletilmiş Kullanıcı bilgilerini veritabanına kaydediyoruz
                    final DatabaseReference userRef = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                    ).ref("kullanicilar/$uid");
  
                    await userRef.set({
                      'ad': adController.text.trim(),
                      'soyad': soyadController.text.trim(),
                      'telefon': telefonController.text.trim(),
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
                      'islem': 'Yeni detaylı hesap oluşturdu ($secilenRol - ${adController.text.trim()})',
                      'tarih': ServerValue.timestamp,
                    });
  
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kayıt Başarılı ve Detaylar Eklendi!')),
                    );
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                child: const Text("Kayıt Ol ve Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}