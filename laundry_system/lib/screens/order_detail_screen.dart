import 'package:flutter/material.dart';
import 'profile_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text("Sipariş Detayı"),
  actions: [
    IconButton(
      icon: Icon(Icons.person),
      onPressed: () {
        // Sağ üstteki profil ikonuna basınca Profil Ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      },
    )
  ],
),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text("Siparişiniz Kurutma Aşamasında", style: TextStyle(fontSize: 18)),
            Text("Kalan Süre: 15 Dakika"),
          ],
        ),
      ),
    );
  }
}