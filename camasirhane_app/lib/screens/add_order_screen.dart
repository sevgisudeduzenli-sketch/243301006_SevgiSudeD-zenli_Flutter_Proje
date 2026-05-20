import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'payment_screen.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final TextEditingController makineNoController = TextEditingController();

  String secilenTur = 'Renkliler';
  String secilenKilo = '5 kg';
  String kurutmaSecimi = 'Hayır';

  int fiyatHesapla() {
    int tabanFiyat = 40;
    if (secilenTur == 'Hassaslar / Yünlüler') {
      tabanFiyat = 50;
    }
    if (secilenKilo == '10 kg') {
      tabanFiyat += 20;
    }
    if (kurutmaSecimi == 'Evet') {
      tabanFiyat += 15;
    }
    return tabanFiyat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gelişmiş Sipariş Ekle"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: secilenTur,
                decoration: const InputDecoration(labelText: "Çamaşır Türü", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Renkliler', child: Text('Renkliler (40 TL)')),
                  DropdownMenuItem(value: 'Beyazlar', child: Text('Beyazlar (40 TL)')),
                  DropdownMenuItem(value: 'Hassaslar / Yünlüler', child: Text('Hassaslar / Yünlüler (50 TL)')),
                ],
                onChanged: (yeniDeger) {
                  setState(() {
                    secilenTur = yeniDeger!;
                  });
                },
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: secilenKilo,
                decoration: const InputDecoration(labelText: "Çamaşır Kapsam / Kilo", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: '5 kg', child: Text('5 kg (Ek Ücret Yok)')),
                  DropdownMenuItem(value: '10 kg', child: Text('+10 kg (+20 TL)')),
                ],
                onChanged: (yeniDeger) {
                  setState(() {
                    secilenKilo = yeniDeger!;
                  });
                },
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: kurutmaSecimi,
                decoration: const InputDecoration(labelText: "Kurutma Hizmeti İstiyor musunuz?", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Hayır', child: Text('Hayır (0 TL)')),
                  DropdownMenuItem(value: 'Evet', child: Text('Evet (+15 TL)')),
                ],
                onChanged: (yeniDeger) {
                  setState(() {
                    kurutmaSecimi = yeniDeger!;
                  });
                },
              ),
              const SizedBox(height: 15),

              TextField(
                controller: makineNoController,
                decoration: const InputDecoration(
                  labelText: "Makine Numarası Seçin (1 - 15 Arası)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    "Toplam Tutar: ${fiyatHesapla()} TL",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  if (makineNoController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen makine numarasını girin!')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        camasirTur: secilenTur,
                        kilo: secilenKilo,
                        kurutma: kurutmaSecimi,
                        makineNo: makineNoController.text.trim(),
                        ucret: fiyatHesapla(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Ödeme Adımına Geç",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}