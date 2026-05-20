import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> siparisVerisi;

  const OrderDetailScreen({super.key, required this.siparisVerisi});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Timer? _sayacTimer;
  int _kalanSaniye = 30; // Jüri testi için tam ideal süre
  bool _sureBittiMi = false;

  @override
  void initState() {
    super.initState();
    _sayaciBaslat();
  }

  void _sayaciBaslat() {
    _sayacTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_kalanSaniye > 0) {
        setState(() {
          _kalanSaniye--;
        });
      } else {
        _sayacTimer?.cancel();
        if (!_sureBittiMi) {
          setState(() {
            _sureBittiMi = true;
          });
          _durumuGuncelleVeBildirimVer();
        }
      }
    });
  }

  void _durumuGuncelleVeBildirimVer() async {
    try {
      String siparisId = widget.siparisVerisi['id'] ?? '';
      
      if (siparisId.isNotEmpty) {
        // 1. Firebase Realtime Database'deki durum bilgisini güncelliyoruz
        final DatabaseReference guncelleRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
        ).ref("siparisler/$siparisId");

        await guncelleRef.update({
          'durum': 'Yıkandı (Teslim Alınabilir)',
        });

        // 2. İşlem logunu veritabanına fırlatıyoruz
        final DatabaseReference logRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
        ).ref("logs");

        await logRef.push().set({
          'kullanici': widget.siparisVerisi['kullanici'] ?? 'Bilinmeyen',
          'islem': 'Çamaşır yıkama süresi doldu, sistem siparişi otomatik güncelledi.',
          'tarih': ServerValue.timestamp,
        });
      }

      // 3. Ekranda şık bir bildirim kutusu açıyoruz
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text("İşlem Tamamlandı!"),
              ],
            ),
            content: const Text("Çamaşırınızın yıkanma işlemi başarıyla bitti. Makineden teslim alabilirsiniz!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Bildirimi kapat
                  Navigator.of(context).pop(); // Ana sayfaya geri dön
                },
                child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

    } catch (e) {
      debugPrint("Firebase Güncelleme Hatası: $e");
    }
  }

  @override
  void dispose() {
    _sayacTimer?.cancel();
    super.dispose();
  }

  String _sureFormatiniAl() {
    int dakika = _kalanSaniye ~/ 60;
    int saniye = _kalanSaniye % 60;
    String dakikaStr = dakika.toString().padLeft(2, '0');
    String saniyeStr = saniye.toString().padLeft(2, '0');
    return "$dakikaStr:$saniyeStr";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sipariş Durumu Detayı"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_laundry_service, color: Colors.blue, size: 60),
                  const SizedBox(height: 15),
                  Text(
                    widget.siparisVerisi['camasirTuru'] ?? 'Çamaşır Siparişi',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Makine Numarası: ${widget.siparisVerisi['makineNo']}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Divider(height: 30, thickness: 1),
                  
                  // Canlı Dijital Sayaç Görünümü
                  Text(
                    _sureBittiMi ? "SÜRE DOLDU" : "Yıkama İşleminin Bitmesine Kalan Süre",
                    style: TextStyle(fontSize: 14, color: _sureBittiMi ? Colors.green : Colors.blueGrey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _sureFormatiniAl(),
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold, 
                      color: _sureBittiMi ? Colors.green : Colors.blue,
                      fontFamily: 'Courier', // Dijital saat havası versin diye
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    "Durum: ${_sureBittiMi ? 'Yıkandı' : widget.siparisVerisi['durum']}",
                    style: TextStyle(
                      fontSize: 16, 
                      color: _sureBittiMi ? Colors.green : Colors.orange, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}