import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  String secilenCamasirTuru = "Renkliler";
  String secilenKilo = "0-5 Kg";
  String kurutmaHizmeti = "Kurutma İstemiyorum"; 
  String? secilenMakineNo;

  final List<String> camasirTurleri = ["Renkliler", "Beyazlar", "Pamuklular", "Hassas / Yünlüler", "Sentetikler", "Yorgan / Battaniye"];
  final List<String> kiloSecenekleri = ["0-5 Kg", "5-10 Kg", "10+ Kg"];
  final List<String> kurutmaSecenekleri = ["Kurutma İstemiyorum", "Kurutma İstiyorum"];

  int get programSuresiSaniye {
    switch (secilenCamasirTuru) {
      case "Renkliler": return 30;
      case "Beyazlar": return 35;
      case "Pamuklular": return 40;
      case "Hassas / Yünlüler": return 25;
      case "Sentetikler": return 30;
      case "Yorgan / Battaniye": return 50;
      default: return 30;
    }
  }

  int get toplamTutar {
    int ucret = (secilenCamasirTuru == "Yorgan / Battaniye") ? 70 : 40;
    if (secilenKilo == "5-10 Kg") ucret += 15; else if (secilenKilo == "10+ Kg") ucret += 30;
    if (kurutmaHizmeti == "Kurutma İstiyorum") ucret += 25; 
    return ucret;
  }

  void _bosVeSaglamMakineSec() async {
    final siparisSnapshot = await FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com').ref("siparisler").get();
    final arizaSnapshot = await FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com').ref("arizali_makineler").get();

    Set<String> engelliler = {};
    if (siparisSnapshot.exists) {
      (siparisSnapshot.value as Map).forEach((k, v) {
        // Havuzda olan her makine (durumu ne olursa olsun teslim alınana kadar) kilitli kalır
        engelliler.add(v['makineNo'].toString());
      });
    }
    if (arizaSnapshot.exists) {
      (arizaSnapshot.value as Map).forEach((k, v) {
        if (k.toString().startsWith("M-")) engelliler.add(k.toString().replaceAll("M-", ""));
      });
    }

    List<String> boslar = [];
    for (int i = 1; i <= 15; i++) if (!engelliler.contains(i.toString())) boslar.add(i.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Müsait Makine Seç", style: TextStyle(color: Colors.white)),
        content: SizedBox(width: double.maxFinite, child: ListView.builder(
          shrinkWrap: true,
          itemCount: boslar.length,
          itemBuilder: (c, i) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text("M-${boslar[i]} Müsait", style: const TextStyle(color: Colors.white)),
            onTap: () { setState(() => secilenMakineNo = boslar[i]); Navigator.pop(context); },
          ),
        )),
      ),
    );
  }

  void _odemeEkraniniAc() {
    if (secilenMakineNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce boş bir makine seçin!")));
      return;
    }

    final formKey = GlobalKey<FormState>();
    String kartNo = "", skt = "", cvv = "", adSoyad = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text("Güvenli Kart Ödemesi ($toplamTutar TL)", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _kartInputDekorasyonu("Kart Üzerindeki İsim Soyisim"),
                    onChanged: (v) => adSoyad = v,
                    validator: (v) => v!.isEmpty ? "İsim soyisim gerekli" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _KartNoFormatter(),
                    ],
                    decoration: _kartInputDekorasyonu("Kart Numarası (16 Hane)"),
                    onChanged: (v) => kartNo = v,
                    validator: (v) => v!.length < 19 ? "Geçersiz Kart Numarası" : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _SktFormatter(),
                          ],
                          decoration: _kartInputDekorasyonu("AA/YY"),
                          onChanged: (v) => skt = v,
                          validator: (v) => v!.length < 5 ? "Hatalı" : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: _kartInputDekorasyonu("CVV"),
                          onChanged: (v) => cvv = v,
                          validator: (v) => v!.length < 3 ? "Hatalı" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: Colors.green.shade600),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context); 
                        _simuleEtVeKaydet(); 
                      }
                    },
                    child: const Text("Ödemeyi Tamamla ve Siparişi Aç", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _kartInputDekorasyonu(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withAlpha(15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Oluştur"), backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.grey.shade900], begin: Alignment.topCenter)),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Lütfen Yıkama Programı Seçin", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _dropdownContainer(secilenCamasirTuru, camasirTurleri, (v) => setState(() => secilenCamasirTuru = v!)),
          const SizedBox(height: 4),
          Text("⏱️ Program Süresi: $programSuresiSaniye Saniye", style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 20),
          const Text("Kıyafetlerinizin Tahmini Kilogramını Seçin", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _dropdownContainer(secilenKilo, kiloSecenekleri, (v) => setState(() => secilenKilo = v!)),
          
          const SizedBox(height: 20),
          const Text("Ekstra Kurutma Hizmeti Durumu (+25 TL)", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _dropdownContainer(kurutmaHizmeti, kurutmaSecenekleri, (v) => setState(() => kurutmaHizmeti = v!)),
          
          const SizedBox(height: 25),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: Colors.blue.shade600),
            icon: const Icon(Icons.search, color: Colors.white),
            label: Text(secilenMakineNo == null ? "Boş Makine Bul" : "Seçilen: M-$secilenMakineNo", style: const TextStyle(color: Colors.white)),
            onPressed: _bosVeSaglamMakineSec,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Toplam: $toplamTutar TL", style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(onPressed: _odemeEkraniniAc, child: const Text("Onayla ve Öde")),
            ]),
          )
        ]),
      ),
    );
  }

  Widget _dropdownContainer(String v, List<String> l, ValueChanged<String?> c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: v, isExpanded: true, dropdownColor: Colors.grey.shade900, style: const TextStyle(color: Colors.white),
        items: l.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: c,
      )),
    );
  }

  void _simuleEtVeKaydet() async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    await Future.delayed(const Duration(seconds: 1));
    final ref = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com').ref("siparisler").push();
    
    String dbKurutmaMetni = (kurutmaHizmeti == "Kurutma İstiyorum") ? "Evet" : "Hayır";

    await ref.set({
      'camasirTuru': secilenCamasirTuru, 'makineNo': secilenMakineNo, 'kurutmaMakineNo': '',
      'durum': 'Sipariş Alındı (Yıkanıyor)', 'kurutma': dbKurutmaMetni, 'ucret': toplamTutar,
      'siparisZamani': DateTime.now().millisecondsSinceEpoch, 'toplamSure': programSuresiSaniye, 'kullanici': 'Öğrenci'
    });
    Navigator.pop(context); Navigator.pop(context);
  }
}

class _KartNoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(" ", "");
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) buffer.write(" ");
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.length));
  }
}

class _SktFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll("/", "");
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) buffer.write("/");
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.length));
  }
}