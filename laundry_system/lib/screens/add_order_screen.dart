import 'package:flutter/material.dart';

class AddOrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yeni Sipariş Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(decoration: InputDecoration(labelText: "Çamaşır Türü (Örn: Renkli)")),
            TextField(decoration: InputDecoration(labelText: "Tahmini KG")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: Text("Siparişi Oluştur")),
          ],
        ),
      ),
    );
  }
}