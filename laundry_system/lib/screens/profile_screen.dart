import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profilim")),
      body: Column(
        children: [
          SizedBox(height: 20),
          CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          ListTile(title: Text("Ad Soyad"), subtitle: Text("Sevgi Sude Düzenli")),
          ListTile(title: Text("E-posta"), subtitle: Text("sudee@gmail.com")),
          ElevatedButton(onPressed: () {}, child: Text("Çıkış Yap")),
        ],
      ),
    );
  }
}