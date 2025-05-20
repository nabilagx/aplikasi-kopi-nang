import 'package:flutter/material.dart';
import 'package:kopinang/screens/home_admin.dart';
import 'package:kopinang/screens/kelola_produk.dart';

class DrawerAdmin extends StatelessWidget {
  final BuildContext context;

  const DrawerAdmin(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'KOPI NANG',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Beranda'),
            onTap: () {
              Navigator.pushReplacement(
                this.context,
                MaterialPageRoute(builder: (_) => HomeAdmin()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.coffee),
            title: Text('Kelola Produk'),
            onTap: () {
              Navigator.pushReplacement(
                this.context,
                MaterialPageRoute(builder: (_) => KelolaProdukPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
