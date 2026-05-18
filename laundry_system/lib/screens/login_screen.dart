import 'package:flutter/material.dart';
import 'home_screen.dart';
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Çamaşırhane Giriş")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: "E-posta"),
            ),
            TextField(
              decoration: InputDecoration(labelText: "Şifre"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
  // Giriş yap butonuna basınca Ana Sayfaya (HomeScreen) git
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HomeScreen()),
  );
},
              child: Text("Giriş Yap"),
            ),
          ],
        ),
      ),
    );
  }
}