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
        title: Text("Çamaşırhane ($kullaniciRolu Sürümü)"),
        backgroundColor: Colors.blue,
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

          // Aktif dolu makineleri hafızada tutmak için bir set oluşturuyoruz
          Set<String> doluMakineler = {};
          List<Map<dynamic, dynamic>> siparisListesi = [];

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> hamVeri = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            
            hamVeri.forEach((key, value) {
              String makineNo = (value['makineNo'] ?? '').toString();
              String durum = value['durum'] ?? '';
              
              // Eğer makine "Yıkanıyor" veya "Sipariş Alındı" durumundaysa dolu kabul et
              if (durum.contains('Yıkanıyor') || durum.contains('Alındı')) {
                doluMakineler.add(makineNo);
              }

              siparisListesi.add({
                'id': key,
                'camasirTuru': value['camasirTuru'] ?? 'Bilinmiyor',
                'makineNo': makineNo,
                'durum': durum,
                'ucret': value['ucret'] ?? 0,
                'kullanici': value['kullanici'] ?? '',
              });
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KISIM: 15 MAKiNELi DOLULUK PANELi BAŞLIĞI
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Makinelerin Canlı Doluluk Durumu (1 - 15)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),

              // 15 Makinenin Şık Grid Görünümü
              Container(
                height: 140, // Panelin ekranda kaplayacağı alan
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal, // Yatayda kaysın diye yana çevirdik
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 satır halinde dizilsinler
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 15, // Toplam 15 makine
                  itemBuilder: (context, index) {
                   int makineNumarasi = index + 1;
bool doluMu = doluMakineler.contains(makineNumarasi.toString());

                    return Container(
                      decoration: BoxDecoration(
                        color: doluMu ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: doluMu ? Colors.red : Colors.green),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_laundry_service,
                            color: doluMu ? Colors.red : Colors.green,
                            size: 24,
                          ),
                          Text(
                            "M-$makineNumarasi",
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: doluMu ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                          Text(
                            doluMu ? "DOLU" : "BOŞ",
                            style: TextStyle(fontSize: 9, color: doluMu ? Colors.red : Colors.green),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 25, thickness: 1),

              // 2. KISIM: SİPARİŞLER LİSTESİ BAŞLIĞI
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "Aktif Sipariş Havuzu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 5),

              // Siparişlerin Listelendiği Alan
              Expanded(
                child: siparisListesi.isEmpty
                    ? const Center(child: Text("Henüz hiç sipariş bulunmuyor."))
                    : ListView.builder(
                        itemCount: siparisListesi.length,
                        itemBuilder: (context, index) {
                          final siparis = siparisListesi[index];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.local_laundry_service, color: Colors.blue),
                              title: Text("${siparis['camasirTuru']} (Makine: ${siparis['makineNo']})"),
                              subtitle: Text("Durum: ${siparis['durum']} | Tutar: ${siparis['ucret']} TL"),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                             onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrderDetailScreen(siparisVerisi: siparis),
    ),
  );
},
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: kullaniciRolu == "Öğrenci"
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddOrderScreen()),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}