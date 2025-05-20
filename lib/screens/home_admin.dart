import 'package:flutter/material.dart';
import 'package:kopinang/screens/kelola_produk.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({Key? key}) : super(key: key);

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  String _selectedMenu = 'Dashboard';

  void _onSelectMenu(String menu) {
    Navigator.pop(context);
    setState(() {
      _selectedMenu = menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - $_selectedMenu'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu Admin',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => _onSelectMenu('Dashboard'),
            ),
            ListTile(
              leading: Icon(Icons.store),
              title: Text('Kelola Produk/Menu'),
              onTap: () {
                Navigator.pop(context); // tutup drawer dulu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KelolaProdukPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Kelola Pesanan'),
              onTap: () => _onSelectMenu('Kelola Pesanan'),
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Promosi & Notifikasi'),
              onTap: () => _onSelectMenu('Promosi & Notifikasi'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Laporan Penjualan'),
              onTap: () => _onSelectMenu('Laporan Penjualan'),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review_sharp),
              title: const Text('Kelola Rating & Ulasan'),
              onTap: () => _onSelectMenu('Kelola Rating & Ulasan'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Lokasi Customer'),
              onTap: () => _onSelectMenu('Lokasi Customer'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Verifikasi Pesanan'),
              onTap: () => _onSelectMenu('Verifikasi Pesanan'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Tambah Admin Baru'),
              onTap: () => _onSelectMenu('Tambah Admin Baru'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Halaman $_selectedMenu',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
