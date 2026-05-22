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
  final User? user = FirebaseAuth.instance.currentUser;
  
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _rolController = TextEditingController(); 
  
  String _sistemRolu = "Öğrenci"; 
  bool _loading = true;

  final List<String> _yetkiliYneticiler = [
    "sevgisude@email.com",
    "aysenur@email.com"
  ];

  @override
  void initState() {
    super.initState();
    _bilgileriGetir();
  }

  void _bilgileriGetir() async {
    if (user != null) {
      String anlikEmail = user!.email?.toLowerCase().trim() ?? "";
      if (_yetkiliYneticiler.contains(anlikEmail)) {
        _sistemRolu = "Personel";
      }

      try {
        final ref = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
        ).ref("kullanicilar/${user!.uid}");

        final snapshot = await ref.get();
        if (snapshot.exists && snapshot.value != null) {
          Map data = snapshot.value as Map;
          setState(() {
            _adController.text = (data['adSoyad'] ?? "").toString();
            _emailController.text = (data['email'] ?? user!.email ?? "").toString();
            _telController.text = (data['telefon'] ?? "").toString();
            _sistemRolu = (data['rol'] ?? _sistemRolu).toString();
            _rolController.text = _sistemRolu;
            _loading = false;
          });
        } else {
          setState(() {
            _emailController.text = user!.email ?? "";
            _rolController.text = _sistemRolu;
            _loading = false;
          });
        }
      } catch (e) {
        setState(() {
          _emailController.text = user!.email ?? "";
          _rolController.text = _sistemRolu;
          _loading = false;
        });
      }
    } else {
      setState(() => _loading = false);
    }
  }

  void _bilgileriGuncelle() async {
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
      ).ref("kullanicilar/${user!.uid}");

      await ref.update({
        'adSoyad': _adController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'telefon': _telController.text.trim(),
        'rol': _sistemRolu, 
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil başarıyla güncellendi!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _adController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Ayarları", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.grey.shade900],
          ),
        ),
        child: _loading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade400, width: 3)),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.person, size: 80, color: Colors.blue.shade300),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _adController.text.isEmpty ? "Kullanıcı Profili" : _adController.text,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(_sistemRolu, style: TextStyle(color: Colors.blue.shade300, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),

                  _profilInput("Ad Soyad", _adController, Icons.person_outline, true),
                  const SizedBox(height: 15),
                  _profilInput("E-posta Adresi", _emailController, Icons.email_outlined, true),
                  const SizedBox(height: 15),
                  _profilInput("Telefon Numarası", _telController, Icons.phone_android_outlined, true),
                  const SizedBox(height: 15),
                  _profilInput("Sistem Rolü (Değiştirilemez)", _rolController, Icons.admin_panel_settings_outlined, false),
                  
                  const SizedBox(height: 40),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    icon: const Icon(Icons.save_as_rounded),
                    label: const Text("Bilgileri Güncelle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    onPressed: _bilgileriGuncelle,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextButton(
                    onPressed: () async {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          await FirebaseDatabase.instanceFor(
                            app: Firebase.app(),
                            databaseURL: 'https://camasirhane-fcde0-default-rtdb.firebaseio.com',
                          ).ref("log_kayitlari").push().set({
                            'kullaniciId': user.uid,
                            'email': user.email,
                            'islem': 'Sistemden Güvenli Çıkış Yapıldı',
                            'zaman': ServerValue.timestamp,
                          });
                        } catch (_) {}
                      }

                      if (!mounted) return;

                      Navigator.pop(context);

                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text("Güvenli Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _profilInput(String label, TextEditingController controller, IconData icon, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white.withAlpha(15) : Colors.black.withAlpha(50),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: enabled ? Colors.white.withAlpha(30) : Colors.transparent),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled, 
            style: TextStyle(color: enabled ? Colors.white : Colors.white38, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? Colors.blue.shade400 : Colors.white24),
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}