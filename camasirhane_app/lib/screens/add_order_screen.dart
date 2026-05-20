import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final TextEditingController camasirTuruController = TextEditingController();
  final TextEditingController makineNoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Sipariş Ekle"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: camasirTuruController,
              decoration: const InputDecoration(
                labelText: "Çamaşır Türü (Örn: Renkliler, Beyazlar)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: makineNoController,
              decoration: const InputDecoration(
                labelText: "Makine Numarası (Örn: 3, 5)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                // Alanlar boşsa işlem yapma
                if (camasirTuruController.text.isEmpty || makineNoController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
                  );
                  return;
                }

                try {
                  final User? gecerliKullanici = FirebaseAuth.instance.currentUser;
                  String eposta = gecerliKullanici?.email ?? "Bilinmeyen";

                  // 1. Sipariş verisini Realtime Database'e ekliyoruz
                  final DatabaseReference siparisRef = FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                  ).ref("siparisler");

                  // push() kullanarak her siparişe benzersiz bir ID veriyoruz
                  await siparisRef.push().set({
                    'kullanici': eposta,
                    'camasirTuru': camasirTuruController.text.trim(),
                    'makineNo': makineNoController.text.trim(),
                    'durum': 'Yıkanıyor', // Varsayılan durum
                    'tarih': ServerValue.timestamp,
                  });

                  // 2. İŞLEM LOGU: Hocanın istediği veri ekleme logunu fırlatıyoruz
                  final DatabaseReference logRef = FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                  ).ref("logs");

                  await logRef.push().set({
                    'kullanici': eposta,
                    'islem': 'Yeni bir çamaşır siparişi oluşturdu (Makine: ${makineNoController.text.trim()})',
                    'tarih': ServerValue.timestamp,
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sipariş Alındı ve Log Kaydedildi!')),
                  );

                  // İşlem bitince bir önceki ekrana (Ana Sayfaya) geri dön
                  Navigator.pop(context);

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sipariş eklenirken hata çıktı: $e')),
                  );
                }
              },
              child: const Text(
                "Siparişi Tamamla ve Gönder",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}