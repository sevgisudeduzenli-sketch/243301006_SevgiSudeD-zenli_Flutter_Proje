import 'package:flutter/material.dart';
import 'add_order_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Siparişlerim")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.local_laundry_service),
            title: Text("Sipariş #1024"),
            subtitle: Text("Durum: Yıkanıyor"),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            leading: Icon(Icons.local_laundry_service),
            title: Text("Sipariş #1025"),
            subtitle: Text("Durum: Teslim Edildi"),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
  // Artı butonuna basınca Sipariş Ekleme Sayfasına git
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => AddOrderScreen()),
  );
},
        child: Icon(Icons.add),
      ),
    );
  }
}