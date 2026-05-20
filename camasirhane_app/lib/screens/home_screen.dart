import 'package:flutter/material.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';
import 'profile_screen.dart'; // Profil ekranına geçebilmek için bunu ekledik

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ın içine hem senin başlığını hem de profil geçiş butonunu yerleştirdik
      appBar: AppBar(
        title: const Text("Siparişlerim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.local_laundry_service),
            title: const Text("Sipariş #1024"),
            subtitle: const Text("Durum: Yıkanıyor"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderDetailScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_laundry_service),
            title: const Text("Sipariş #1025"),
            subtitle: const Text("Durum: Teslim Edildi"),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Artı butonuna basınca Sipariş Ekleme Sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddOrderScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}