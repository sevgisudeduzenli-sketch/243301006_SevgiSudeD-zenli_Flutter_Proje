import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // Çıkış yapınca fırlatacağımız ekran

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Şu an giriş yapmış olan kullanıcının bilgisini çekiyoruz
    final User? gecerliKullanici = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Bilgileri"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                "Aktif Kullanıcı E-postası:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                gecerliKullanici?.email ?? "Bilinmeyen Kullanıcı",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // İŞTE ARADIĞIMIZ ÇIKIŞ YAP BUTONU!
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Dikkat çeksin diye kırmızı yaptık
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Oturumu Kapat / Çıkış Yap",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed: () async {
                  try {
                    String? eposta = gecerliKullanici?.email;

                    // 1. Önce hocanın kuralı için ÇIKIŞ LOGUNU Firebase'e çakıyoruz
                    final DatabaseReference logRef = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                    ).ref("logs");

                    await logRef.push().set({
                      'kullanici': eposta ?? 'Bilinmeyen',
                      'islem': 'Sistemden çıkış yaptı',
                      'tarih': ServerValue.timestamp,
                    });

                    // 2. Firebase Auth oturumunu resmi olarak kapatıyoruz
                    await FirebaseAuth.instance.signOut();

                    // 3. Kullanıcıyı Giriş Ekranına tekmeliyoruz
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false, // Geri tuşuna basınca tekrar profile dönemesin diye geçmişi sildik
                    );

                  } catch (e) {
                    debugPrint("Çıkış Log Hatası: $e");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}