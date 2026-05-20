import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String ad = "Yükleniyor...";
  String soyad = "";
  String telefon = "Yükleniyor...";
  String rol = "Yükleniyor...";
  String eposta = "";

  @override
  void initState() {
    super.initState();
    kullaniciDetaylariniCek();
  }

  void kullaniciDetaylariniCek() async {
    final User? gecerliKullanici = FirebaseAuth.instance.currentUser;
    if (gecerliKullanici != null) {
      String uid = gecerliKullanici.uid;
      setState(() {
        eposta = gecerliKullanici.email ?? "";
      });

      final DatabaseReference userRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
      ).ref("kullanicilar/$uid");

      final DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> veri = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          ad = veri['ad'] ?? "Bilinmiyor";
          soyad = veri['soyad'] ?? "";
          telefon = veri['telefon'] ?? "Bilinmiyor";
          rol = veri['rol'] ?? "Öğrenci";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Bilgileri"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: const Text("Ad Soyad"),
                          // HATA DÜZELTİLDİ: Colors.black87 yapıldı
                          subtitle: Text("$ad $soyad", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.email, color: Colors.blue),
                          title: const Text("E-posta Adresi"),
                          // HATA DÜZELTİLDİ: Colors.black87 yapıldı
                          subtitle: Text(eposta, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone, color: Colors.blue),
                          title: const Text("Telefon Numarası"),
                          // HATA DÜZELTİLDİ: Colors.black87 yapıldı
                          subtitle: Text(telefon, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.badge, color: Colors.blue),
                          title: const Text("Sistem Rolü"),
                          subtitle: Text(rol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Oturumu Kapat / Çıkış Yap",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    try {
                      final DatabaseReference logRef = FirebaseDatabase.instanceFor(
                        app: Firebase.app(),
                        databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                      ).ref("logs");

                      await logRef.push().set({
                        'kullanici': eposta,
                        'islem': 'Sistemden çıkış yaptı (Kullanıcı: $ad)',
                        'tarih': ServerValue.timestamp,
                      });

                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
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
      ),
    );
  }
}