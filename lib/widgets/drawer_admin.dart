import 'package:flutter/material.dart';
import 'package:kopinang/screens/kelola_produk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kopinang/screens/add_admin.dart';
import 'package:kopinang/screens/login_screen.dart';
import 'package:kopinang/screens/setting_akun.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kopinang/screens/promo.dart';



class DrawerAdmin extends StatelessWidget {
  final BuildContext scaffoldContext;
  final Function(String)? onSelectMenu;

  const DrawerAdmin({
    super.key,
    required this.scaffoldContext,
    this.onSelectMenu,
  });


  void _handleSelect(String menu) {
    Navigator.pop(scaffoldContext);
    if (onSelectMenu != null) {
      onSelectMenu!(menu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    return Drawer(
      width: 250,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFFE4EAFF),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 80,
                  child: Image.asset(
                      'assets/images/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Menu Admin',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => _handleSelect('Dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Kelola Produk/Menu'),
            onTap: () {
              Navigator.pop(scaffoldContext);
              Navigator.push(
                scaffoldContext,
                MaterialPageRoute(builder: (_) => KelolaProdukPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Kelola Pesanan'),
            onTap: () => _handleSelect('Kelola Pesanan'),
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Promosi'),
            onTap: () {
              Navigator.pop(scaffoldContext);
              Navigator.push(
                scaffoldContext,
                MaterialPageRoute(builder: (_) => PromoAdminPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Laporan Penjualan'),
            onTap: () => _handleSelect('Laporan Penjualan'),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_sharp),
            title: const Text('Kelola Rating & Ulasan'),
            onTap: () => _handleSelect('Kelola Rating & Ulasan'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Lokasi Customer'),
            onTap: () => _handleSelect('Lokasi Customer'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Verifikasi Pesanan'),
            onTap: () => _handleSelect('Verifikasi Pesanan'),
          ),

          // HANYA tampil jika UID adalah jATqcWGgqLcAB0PqbEY8oY65RI03
          if (uid == 'jATqcWGgqLcAB0PqbEY8oY65RI03')
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Tambah Admin Baru'),
              onTap: () {
                Navigator.pop(scaffoldContext);
                Navigator.push(
                  scaffoldContext,
                  MaterialPageRoute(builder: (_) => AddAdminPage()),
                );
              },
            ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan Akun'),
            onTap: () {
              Navigator.pop(scaffoldContext);
              Navigator.push(
                scaffoldContext,
                MaterialPageRoute(builder: (_) => PengaturanAkunPage()),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.pop(scaffoldContext);
              Navigator.pushReplacement(
                scaffoldContext,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
