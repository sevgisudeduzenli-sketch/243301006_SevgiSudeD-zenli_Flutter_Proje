import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';
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
    final DatabaseReference siparislerRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
    ).ref("siparisler");

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
      body: StreamBuilder(
        stream: siparislerRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Henüz hiç sipariş bulunmuyor."));
          }

          Map<dynamic, dynamic> hamVeri = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<Map<dynamic, dynamic>> siparisListesi = [];

          hamVeri.forEach((key, value) {
            siparisListesi.add({
              'id': key,
              'camasirTuru': value['camasirTuru'] ?? 'Bilinmiyor',
              'makineNo': value['makineNo'] ?? '-',
              'durum': value['durum'] ?? 'Bekliyor',
              'kullanici': value['kullanici'] ?? '',
            });
          });

          return ListView.builder(
            itemCount: siparisListesi.length,
            itemBuilder: (context, index) {
              final siparis = siparisListesi[index];
              
              return ListTile(
                leading: const Icon(Icons.local_laundry_service, color: Colors.blue),
                title: Text("${siparis['camasirTuru']} (Makine: ${siparis['makineNo']})"),
                subtitle: Text("Durum: ${siparis['durum']}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    // BURADAKİ HATALI CONST TAMAMEN KALDIRILDI!
                    MaterialPageRoute(builder: (context) => OrderDetailScreen()),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: kullaniciRolu == "Öğrenci"
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  // BURADAKİ HATALI CONST TAMAMEN KALDIRILDI!
                  MaterialPageRoute(builder: (context) => AddOrderScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}