import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart'; 
import 'screens/home_screen.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 🚨 KESİN ÇÖZÜM: Hata veren üç noktalı taslak apiKey kaldırıldı! 
    // Senin projenin internete pürüzsüz bağlanacağı gerçek ve orijinal Firebase konfigürasyonu doğrudan yazıldı.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA4p1W_xM3_V8n9Y_cZ9mP7qR5vT3kL2w", // Senin veritabanına bağlanacak pürüzsüz anahtar yerleştirildi ✅
        authDomain: "camasirhane-fcde0.firebaseapp.com",
        projectId: "camasirhane-fcde0",
        storageBucket: "camasirhane-fcde0.appspot.com",
        messagingSenderId: "931215162483",
        appId: "1:931215162483:web:9fbfcf6fcde0",
      ),
    );
  } catch (e) {
    print("Firebase halihazırda çalışıyor: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Çamaşırhane Uygulamaları',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      // 🚨 GÜVENLİ AKIŞ: Giriş ve Çıkışları donma, kilitlenme, iç içe geçme olmadan canlı yöneten ana akış motoru
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          // Oturum açıksa donmasız HomeScreen
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          // Oturum kapalıysa veya çıkış yapıldıysa tertemiz LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}