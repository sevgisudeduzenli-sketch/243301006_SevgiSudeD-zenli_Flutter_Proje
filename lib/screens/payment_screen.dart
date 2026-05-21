import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class PaymentScreen extends StatefulWidget {
  final String camasirTur;
  final String kilo;
  final String kurutma;
  final String makineNo;
  final int ucret;

  const PaymentScreen({
    super.key,
    required this.camasirTur,
    required this.kilo,
    required this.kurutma,
    required this.makineNo,
    required this.ucret,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController kartNoController = TextEditingController();
  final TextEditingController sktController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController isimController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Güvenli Ödeme Ekranı"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ödeme Özeti Kartı
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Ödenecek Tutar:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("${widget.ucret} TL", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const Divider(height: 20),
                      Text("Detay: ${widget.camasirTur} (${widget.kilo}) + Kurutma: ${widget.kurutma}", style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              const Text("Kart Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              TextField(
                controller: isimController,
                decoration: const InputDecoration(labelText: "Kart Üzerindeki İsim", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: kartNoController,
                decoration: const InputDecoration(labelText: "Kart Numarası (16 Hane)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sktController,
                      decoration: const InputDecoration(labelText: "AA/YY", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      decoration: const InputDecoration(labelText: "CVV", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                ),
                onPressed: () async {
                  if (isimController.text.isEmpty || kartNoController.text.isEmpty || sktController.text.isEmpty || cvvController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen tüm kart bilgilerini doldurun!')),
                    );
                    return;
                  }

                  try {
                    final User? gecerliKullanici = FirebaseAuth.instance.currentUser;
                    String eposta = gecerliKullanici?.email ?? "Bilinmeyen";

                    final DatabaseReference siparisRef = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                    ).ref("siparisler");

                    // Sipariş eklenirken zaman damgasını milisaniye olarak ekliyoruz
                    await siparisRef.push().set({
                      'kullanici': eposta,
                      'camasirTuru': widget.camasirTur,
                      'kilo': widget.kilo,
                      'kurutma': widget.kurutma,
                      'makineNo': widget.makineNo,
                      'ucret': widget.ucret,
                      'durum': 'Sipariş Alındı (Yıkanıyor)',
                      'odendi': true,
                      'siparisZamani': DateTime.now().millisecondsSinceEpoch, // ZAMAN AKIŞI İÇİN BURASI ŞART
                      'tarih': ServerValue.timestamp,
                    });

                    final DatabaseReference logRef = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                    ).ref("logs");

                    await logRef.push().set({
                      'kullanici': eposta,
                      'islem': 'Kredi kartı ile ${widget.ucret} TL ödeme yaptı ve sipariş onaylandı.',
                      'tarih': ServerValue.timestamp,
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ödeme Başarılı! Siparişiniz Hazırlanıyor.')),
                    );

                    Navigator.of(context).popUntil((route) => route.isFirst);

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ödeme hatası: $e')),
                    );
                  }
                },
                child: Text(
                  "${widget.ucret} TL Ödemeyi Güvenle Yap",
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}