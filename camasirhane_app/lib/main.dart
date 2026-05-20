import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart'; 
import 'screens/home_screen.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LaundryApp()); // Projenin orijinal ismi olan LaundryApp'i buraya tam oturttuk
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Çamaşırhane Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // StreamBuilder tarayıcının gizli hafızasını (IndexedDB) canlı olarak dinler
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Tarayıcı hafızasından giriş bilgisi okunurken kısa bir yükleniyor döngüsü gösterir
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Eğer tarayıcıda önceden giriş yapmış bir kullanıcı bulunursa direkt Ana Sayfaya yollar
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(); 
          }
          
          // Hafızada kullanıcı yoksa Giriş Ekranını açar
          return const LoginScreen();
        },
      ),
    );
  }
}