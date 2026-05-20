import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import "package:firebase_core/firebase_core.dart";
import "add_order_screen.dart";
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String kullaniciRolu = "Öğrenci"; 

  @override
  void initState() {
    super.initState();
    roluVeritabanindanCek();
  }

  void roluVeritabanindanCek() async {
    final User? gecerliKullanici = FirebaseAuth.instance.currentUser;
    if (gecerliKullanici != null) {
      String uid = gecerliKullanici.uid;

      final DatabaseReference userRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
      ).ref("kullanicilar/$uid/rol");

      final DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        setState(() {
          kullaniciRolu = snapshot.value.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Siparişlerim ($kullaniciRolu Sürümü)"),
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
                // BURADAKİ CONST KALDIRILDI!
                MaterialPageRoute(builder: (context) => AddOrderScreen()), 
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
      floatingActionButton: kullaniciRolu == "Öğrenci"
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  // BURADAKİ CONST KALDIRILDI!
                  MaterialPageRoute(builder: (context) => AddOrderScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}