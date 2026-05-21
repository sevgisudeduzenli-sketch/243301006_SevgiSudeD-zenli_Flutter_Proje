import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> siparisVerisi;

  const OrderDetailScreen({super.key, required this.siparisVerisi});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String kullaniciRolu = "Öğrenci";
  late DatabaseReference _siparisRef;

  @override
  void initState() {
    super.initState();
    roluVeritabanindanCek();
    
    // Detayına girdiğimiz siparişin Firebase referansı
    _siparisRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
    ).ref("siparisler/${widget.siparisVerisi['id']}");
  }

  void roluVeritabanindanCek() async {
    final User? gecerliKullanici = FirebaseAuth.instance.currentUser;
    if (gecerliKullanici != null) {
      final String uid = gecerliKullanici.uid;
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

  // PERSONELİN SİPARİŞİ TAMAMEN SİLME/İPTAL ETME FONKSİYONU
  void _siparisiIptalEt() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Siparişi İptal Et", style: TextStyle(color: Colors.white)),
        content: const Text("Bu aktif siparişi iptal etmek ve veritabanından tamamen silmek istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _siparisRef.remove(); // Firebase'den uçuruyoruz
              if (!mounted) return;
              Navigator.pop(context); // Diyaloğu kapat
              Navigator.pop(context); // Detay ekranından ana sayfaya dön
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sipariş başarıyla iptal edildi ve makine boşaltıldı.")),
              );
            },
            child: const Text("Evet, İptal Et"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kullaniciRolu == "Öğrenci" ? "Sipariş Takibi" : "Yönetim Paneli Detay"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.grey.shade900],
          ),
        ),
        child: StreamBuilder(
          stream: _siparisRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            // Eğer sipariş personel tarafından silindiyse veya yoksa ekranda hata vermemesi için koruma
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Center(
                child: Text(
                  "Bu işlem havuzdan kaldırılmış veya tamamlanmış.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final Map<dynamic, dynamic> guncelSiparis = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final String guncelDurum = (guncelSiparis['durum'] ?? '').toString();
            
            String gosterilecekDurumText = guncelDurum;
            if (guncelDurum == 'Yıkandı (Teslim Alınabilir)' || guncelDurum == 'Kurutma Bitti (Teslim Alınabilir)') {
              gosterilecekDurumText = 'Çamaşır Alınmaya Hazır';
            }

            final String kNo = guncelSiparis['kurutmaMakineNo'].toString();
            final String makineIbaresi = kNo.isNotEmpty && kNo != 'null' 
                ? "M-${guncelSiparis['makineNo']} ➔ K-$kNo" 
                : "M-${guncelSiparis['makineNo']}";

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Bilgi Kartı
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(38)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            guncelDurum.contains('Kurutuluyor') ? Icons.wind_power : Icons.local_laundry_service,
                            size: 64,
                            color: guncelDurum.contains('Kurutuluyor') ? Colors.orange : Colors.blue.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "${guncelSiparis['camasirTuru']}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "İstasyon Konumu: $makineIbaresi",
                            style: const TextStyle(fontSize: 15, color: Colors.white70),
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          
                          // Dinamik Durum Çubuğu Alanı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Güncel Aşama:", style: TextStyle(color: Colors.white70, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: gosterilecekDurumText == "Çamaşır Alınmaya Hazır" ? Colors.green.withAlpha(51) : Colors.blue.withAlpha(51),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: gosterilecekDurumText == "Çamaşır Alınmaya Hazır" ? Colors.green : Colors.blue),
                                ),
                                child: Text(
                                  gosterilecekDurumText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: gosterilecekDurumText == "Çamaşır Alınmaya Hazır" ? Colors.green.shade300 : Colors.blue.shade300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Hizmet Bedeli:", style: TextStyle(color: Colors.white70, fontSize: 15)),
                              Text("${guncelSiparis['ucret']} TL", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // PERSONEL/YÖNETİCİ EKRANINA ÖZEL KIRMIZI İPTAL ETME BUTONU
                    if (kullaniciRolu != "Öğrenci") ...[
                      const Text(
                        "Yönetici İşlemleri",
                        style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.delete_forever, size: 24),
                          label: const Text(
                            "Siparişi İptal Et ve Sil",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _siparisiIptalEt, // İptal tetikleyicisi
                        ),
                      ),
                    ] else ...[
                      // Eğer giriş yapan öğrenciyse bilgilendirme notu görebilir
                      const Text(
                        "🔒 Sistem akıllı sensörlerle otomatik olarak yönetilmektedir. Süre bittiğinde istasyon durumu güncellenecektir.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}