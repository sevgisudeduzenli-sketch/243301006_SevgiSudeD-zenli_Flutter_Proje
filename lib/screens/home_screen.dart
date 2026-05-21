import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'add_order_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String kullaniciRolu = "Öğrenci"; 
  Timer? _bgGlobalTimer;
  Map<String, bool> arizaliMakineler = {}; 

  // Firebase stream abonelikleri saklama alanı
  StreamSubscription<DatabaseEvent>? _arizaAboneligi;
  StreamSubscription<DatabaseEvent>? _siparisAboneligi;

  List<Map> siparislerListesi = [];
  bool _veriYukleniyor = true;

  final List<String> _yetkiliYneticiler = [
    "sevgisude@email.com",
    "aysenur@email.com"
  ];

  bool get _yoneticiMi {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    String gEmail = user.email?.toLowerCase().trim() ?? "";
    return _yetkiliYneticiler.contains(gEmail) || kullaniciRolu == "Personel";
  }

  @override
  void initState() {
    super.initState();
    roluVeritabanindanCek();
    arizalariDinle();
    siparisleriDinle();

    // Zamanlayıcı mekanizması
    _bgGlobalTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (FirebaseAuth.instance.currentUser == null) {
        timer.cancel();
        return;
      }

      final int cihazZamani = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
      ).ref("siparisler");

      try {
        final snapshot = await ref.get();
        if (snapshot.exists && snapshot.value != null) {
          Map data = snapshot.value as Map;
          data.forEach((key, value) {
            if (value is Map) {
              String durum = (value['durum'] ?? '').toString();
              var kurutmaKontrol = value['kurutma'];
              bool kurutmaIstiyor = kurutmaKontrol == 'Evet' || kurutmaKontrol == true || kurutmaKontrol == 'true';
              int sZamani = value['siparisZamani'] ?? cihazZamani;
              int kZamani = value['kurutmaZamani'] ?? cihazZamani;
              int toplamSureSaniye = value['toplamSure'] ?? 30;

              if (durum == 'Sipariş Alındı (Yıkanıyor)' || durum == 'Yıkanıyor') {
                int gecen = (cihazZamani - sZamani) ~/ 1000;
                if (gecen >= toplamSureSaniye) { 
                  ref.child(key).update({
                    'durum': kurutmaIstiyor ? 'Yıkandı (Kurutma Bekliyor)' : 'Çamaşır Alınmaya Hazır'
                  });
                }
              }
              if (durum == 'Kurutuluyor') {
                int gecen = (cihazZamani - kZamani) ~/ 1000;
                if (gecen >= 30) { 
                  ref.child(key).update({'durum': 'Çamaşır Alınmaya Hazır'});
                }
              }
            }
          });
        }
      } catch (_) {}
    });
  }

  void arizalariDinle() {
    _arizaAboneligi = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
    ).ref("arizali_makineler").onValue.listen((event) {
      if (mounted) {
        setState(() {
          arizaliMakineler.clear();
          if (event.snapshot.exists && event.snapshot.value != null) {
            Map data = event.snapshot.value as Map;
            data.forEach((key, value) => arizaliMakineler[key.toString()] = value == true);
          }
        });
      }
    }, onError: (error) {
      print("Arıza dinleme abonelik hatası bypass edildi.");
    });
  }

  void siparisleriDinle() {
    _siparisAboneligi = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
    ).ref("siparisler").onValue.listen((event) {
      if (mounted) {
        setState(() {
          siparislerListesi.clear();
          if (event.snapshot.exists && event.snapshot.value != null) {
            (event.snapshot.value as Map).forEach((key, value) {
              siparislerListesi.add({'id': key, ...value});
            });
          }
          _veriYukleniyor = false;
        });
      }
    }, onError: (error) {
      print("Sipariş dinleme abonelik hatası bypass edildi.");
    });
  }

  void roluVeritabanindanCek() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String gEmail = user.email?.toLowerCase().trim() ?? "";
      if (_yetkiliYneticiler.contains(gEmail)) {
        if (mounted) setState(() => kullaniciRolu = "Personel");
      } else {
        try {
          final snapshot = await FirebaseDatabase.instanceFor(
              app: Firebase.app(), 
              databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com'
          ).ref("kullanicilar/${user.uid}/rol").get();
          if (snapshot.exists && mounted) {
            setState(() => kullaniciRolu = snapshot.value.toString());
          }
        } catch (_) {}
      }
    }
  }

  // İşlemciyi kilitlemeyen imha metodu profil tetiklemesi için de hazır
  void tumAbonelikleriKapat() async {
    _bgGlobalTimer?.cancel();
    await _arizaAboneligi?.cancel();
    await _siparisAboneligi?.cancel();
    _arizaAboneligi = null;
    _siparisAboneligi = null;
  }

  void _kurutmaMakinesiSeciciDiyalog(String siparisId, Set<String> doluKurutucular) {
    List<String> bosKurutucular = [];
    for (int i = 1; i <= 15; i++) {
      String no = i.toString();
      if (!doluKurutucular.contains(no) && !(arizaliMakineler["K-$no"] ?? false)) {
        bosKurutucular.add(no);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Boş Kurutma Makinesi Seçin", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: bosKurutucular.isEmpty
              ? const Text("Şu an tüm kurutma makineleri dolu veya arızalı!", style: TextStyle(color: Colors.red))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: bosKurutucular.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const Icon(Icons.wind_power, color: Colors.orange),
                    title: Text("K-${bosKurutucular[i]} (Müsait)", style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      await FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com')
                          .ref("siparisler/$siparisId").update({
                        'durum': 'Kurutuluyor',
                        'makineNo': '', 
                        'kurutmaMakineNo': bosKurutucular[i],
                        'kurutmaZamani': DateTime.now().millisecondsSinceEpoch
                      });
                      if (!mounted) return;
                      Navigator.pop(ctx); 
                      Navigator.pop(context); 
                    },
                  ),
                ),
        ),
      ),
    );
  }

  void _islemYonetimDiyalogu(Map siparis, Set<String> doluKurutucular) {
    String durum = siparis['durum'].toString();
    String id = siparis['id'].toString();
    var kurutmaKontrol = siparis['kurutma'];
    bool kurutmaIstiyor = kurutmaKontrol == 'Evet' || kurutmaKontrol == true || kurutmaKontrol == 'true';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("İşlem Yönetim Merkezi", style: TextStyle(color: Colors.white)),
        content: Text("Mevcut Durum: $durum\n\nBu işlemle ilgili ne yapmak istersiniz?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
          if (_yoneticiMi)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              onPressed: () async {
                await FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com')
                    .ref("siparisler/$id").remove(); 
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("İşlemi İptal Et (Sil)"),
            ),
          if (durum == 'Yıkandı (Kurutma Bekliyor)' && kurutmaIstiyor && !_yoneticiMi)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
              onPressed: () => _kurutmaMakinesiSeciciDiyalog(id, doluKurutucular),
              child: const Text("Kurutucu Seç ve Başlat"),
            ),
          if (durum == 'Çamaşır Alınmaya Hazır' && !_yoneticiMi)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                await FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com')
                    .ref("siparisler/$id").remove(); 
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Teslim Aldım"),
            ),
        ],
      ),
    );
  }

  void _makineYonetimDiyalogu(String makineKodu) {
    if (!_yoneticiMi) return; 
    bool suAnArizali = arizaliMakineler[makineKodu] ?? false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("$makineKodu Durum Yönetimi", style: const TextStyle(color: Colors.white)),
        content: Text(
          suAnArizali 
            ? "Bu makine şu an arızalı. Tamir edildi olarak işaretleyip çalışır duruma getirmek istiyor musunuz?" 
            : "Bu makine şu an çalışıyor. Arızalı olarak işaretlemek istiyor musunuz?", 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: suAnArizali ? Colors.green : Colors.red),
            onPressed: () async {
              final ref = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com').ref("arizali_makineler/$makineKodu");
              if (suAnArizali) {
                await ref.remove(); 
              } else {
                await ref.set(true); 
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text(suAnArizali ? "Çalışıyor Yap" : "Arızalı Yap"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { 
    tumAbonelikleriKapat(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> doluM = {}; 
    final Set<String> doluK = {};

    for (var s in siparislerListesi) {
      String m = s['makineNo'].toString(); 
      String k = s['kurutmaMakineNo'].toString();
      String d = s['durum'].toString();
      if (m.isNotEmpty && m != 'null') doluM.add(m);
      if (k.isNotEmpty && k != 'null' && (d == 'Kurutuluyor' || d.contains('Hazır'))) doluK.add(k);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_yoneticiMi ? "Yönetici Kontrol Merkezi" : "Çamaşırhane Uygulamaları"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        // 🚨 DÜZELTİLDİ: AppBar içindeki o fazlalık çıkış iconu tamamen uçuruldu! ✅
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blue.shade900, Colors.grey.shade900])),
        child: SafeArea(
          child: _veriYukleniyor 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_yoneticiMi ? "Yönetici Paneli" : "Kontrol Merkezi", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(_yoneticiMi ? "Makineleri Yönetmek İçin Üzerine Basılı Tutun" : "İstasyon Canlı Durumu", style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ]),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade400, width: 3)),
                          child: CircleAvatar(
                            radius: 35, 
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.person, color: Colors.blue, size: 40), 
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())).then((_) {
                                  if (FirebaseAuth.instance.currentUser != null) {
                                    roluVeritabanindanCek();
                                  }
                                });
                              }
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _makineGrid("Makineler (M)", 15, "M", doluM),
                  const SizedBox(height: 10),
                  _makineGrid("Kurutucular (K)", 15, "K", doluK),
                  const Spacer(), 
                  _islemHavuzu(siparislerListesi, doluK),
                ],
              ),
        ),
      ),
      floatingActionButton: !_yoneticiMi ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddOrderScreen())), backgroundColor: Colors.blue.shade700, icon: const Icon(Icons.add), label: const Text("Sipariş Ekle")) : null,
    );
  }

  Widget _makineGrid(String baslik, int adet, String tip, Set doluSet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      SizedBox(
        height: 100, 
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: adet,
          itemBuilder: (context, index) {
            String no = (index + 1).toString(); String kod = "$tip-$no";
            bool arizali = arizaliMakineler[kod] ?? false;
            bool dolu = doluSet.contains(no);
            Color renk = arizali ? Colors.grey.shade700 : (dolu ? (tip == "M" ? Colors.red : Colors.orange) : Colors.green);
            
            return GestureDetector(
              onLongPress: () => _makineYonetimDiyalogu(kod),
              child: Container(
                width: 90, 
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: renk.withAlpha(50), borderRadius: BorderRadius.circular(18), border: Border.all(color: renk, width: 2.5)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(arizali ? Icons.warning_amber_rounded : (tip == "M" ? Icons.local_laundry_service : Icons.wind_power), color: renk, size: 30),
                  const SizedBox(height: 5),
                  Text(arizali ? "ARIZA" : kod, style: TextStyle(color: arizali ? Colors.red : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _islemHavuzu(List<Map> liste, Set<String> doluKurutucular) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now().millisecondsSinceEpoch),
      builder: (context, timeSnapshot) {
        final int anlikZaman = timeSnapshot.data ?? DateTime.now().millisecondsSinceEpoch;

        return Container(
          height: 280, 
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.black.withAlpha(120), borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Aktif İşlem Havuzu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Expanded(
              child: liste.isEmpty ? const Center(child: Text("Aktif işlem bulunmuyor.", style: TextStyle(color: Colors.white54, fontSize: 16))) : ListView.builder(
                itemCount: liste.length,
                itemBuilder: (context, i) {
                  var s = liste[i];
                  String d = s['durum'].toString();
                  int sZamani = s['siparisZamani'] ?? anlikZaman;
                  int kZamani = s['kurutmaZamani'] ?? anlikZaman;
                  int toplamSureSaniye = s['toplamSure'] ?? 30;
                  String mMakine = s['makineNo'].toString();
                  String kMakine = s['kurutmaMakineNo'].toString();

                  String altYazi = d;
                  if (d.contains('Yıkanıyor') || d.contains('Alındı')) {
                    int kalan = toplamSureSaniye - ((anlikZaman - sZamani) ~/ 1000);
                    altYazi = kalan > 0 ? "⏳ Yıkanıyor (Kalan: $kalan sn)" : "Yıkama Bitti!";
                  } else if (d == 'Kurutuluyor') {
                    int kalan = 30 - ((anlikZaman - kZamani) ~/ 1000);
                    altYazi = kalan > 0 ? "🌀 Kurutuluyor (Kalan: $kalan sn)" : "Kurutma Bitti!";
                  } else if (d == 'Yıkandı (Kurutma Bekliyor)') {
                    altYazi = _yoneticiMi ? "🔄 Yıkandı! Yönetim/İptal için dokunun." : "🔄 Yıkandı! Kurutma makinesi seçmek için dokunun.";
                  } else if (d == 'Çamaşır Alınmaya Hazır') {
                    altYazi = _yoneticiMi ? "✅ Bitti! Yönetim/İptal için dokunun." : "✅ Temiz! Teslim almak için dokunun.";
                  }

                  bool aksiyonBekliyor = d == 'Yıkandı (Kurutma Bekliyor)' || d == 'Çamaşır Alınmaya Hazır' || _yoneticiMi;
                  String cihazBilgisi = "";
                  if (mMakine.isNotEmpty && mMakine != 'null') cihazBilgisi = "M-$mMakine";
                  if (kMakine.isNotEmpty && kMakine != 'null') {
                    cihazBilgisi = cihazBilgisi.isEmpty ? "K-$kMakine" : "$cihazBilgisi -> K-$kMakine";
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: aksiyonBekliyor ? Colors.blue.withAlpha(40) : Colors.white.withAlpha(20), 
                      borderRadius: BorderRadius.circular(15),
                      border: aksiyonBekliyor ? Border.all(color: Colors.blueAccent, width: 1) : null
                    ),
                    child: ListTile(
                      leading: Icon(
                        d == 'Çamaşır Alınmaya Hazır' ? Icons.check_circle : (d == 'Kurutuluyor' ? Icons.wind_power : Icons.local_laundry_service), 
                        color: d == 'Çamaşır Alınmaya Hazır' ? Colors.green : Colors.blue, size: 22
                      ),
                      title: Text("${s['camasirTuru']} ($cihazBilgisi)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(altYazi, style: TextStyle(color: aksiyonBekliyor ? Colors.amber.shade300 : Colors.white70, fontWeight: aksiyonBekliyor ? FontWeight.bold : FontWeight.normal)),
                      trailing: Icon(_yoneticiMi ? Icons.settings : (aksiyonBekliyor ? Icons.touch_app : Icons.hourglass_bottom), color: Colors.white54, size: 18),
                      onTap: () => _islemYonetimDiyalogu(s, doluKurutucular),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  );
}
}