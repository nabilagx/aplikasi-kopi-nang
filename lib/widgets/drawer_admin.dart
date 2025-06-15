import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import screens
import 'package:kopinang/screens/home_admin.dart';
import 'package:kopinang/screens/kelola_produk.dart';
import 'package:kopinang/screens/admin_order_page.dart';
import 'package:kopinang/screens/promo.dart';
import 'package:kopinang/screens/laporan_penjualan.dart';
import 'package:kopinang/screens/kelola_ulasan.dart';
import 'package:kopinang/screens/lacak_order.dart';
import 'package:kopinang/screens/verifikasi_pesanan.dart';
import 'package:kopinang/screens/add_admin.dart';
import 'package:kopinang/screens/setting_akun.dart';
import 'package:kopinang/screens/login_screen.dart';

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
    const mainColor = Color(0xFF2B4FFF); // biru khas KOPI NANG

    return Drawer(
      width: 260,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFE4EAFF),
            ),
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 82,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Menu Admin',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A), // Biru navy tua
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // MENU UTAMA
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.dashboard, 'Dashboard', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => DashboardAdminPage()),
                  );
                }),
                _drawerItem(Icons.store, 'Kelola Produk/Menu', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => KelolaProdukPage()),
                  );
                }),
                _drawerItem(Icons.list_alt, 'Kelola Pesanan', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => AdminOrderPage()),
                  );
                }),
                _drawerItem(Icons.campaign, 'Promosi', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => PromoAdminPage()),
                  );
                }),
                _drawerItem(Icons.bar_chart, 'Laporan Penjualan', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => LaporanPenjualanPage()),
                  );
                }),
                _drawerItem(Icons.rate_review, 'Kelola Rating & Ulasan', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => KelolaUlasanPage()),
                  );
                }),
                _drawerItem(Icons.location_on, 'Lokasi Customer', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => LacakOrderPage()),
                  );
                }),
                _drawerItem(Icons.qr_code_scanner, 'Verifikasi Pesanan', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => const VerifikasiPesananPage()),
                  );
                }),

                // ADMIN KHUSUS
                if (uid == 'jATqcWGgqLcAB0PqbEY8oY65RI03')
                  _drawerItem(Icons.person_add, 'Tambah Admin Baru', mainColor, () {
                    Navigator.pop(scaffoldContext);
                    Navigator.push(
                      scaffoldContext,
                      MaterialPageRoute(builder: (_) => AddAdminPage()),
                    );
                  }),

                const Divider(),

                // PENGATURAN & LOGOUT
                _drawerItem(Icons.settings, 'Pengaturan Akun', mainColor, () {
                  Navigator.pop(scaffoldContext);
                  Navigator.push(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => PengaturanAkunPage()),
                  );
                }),
                _drawerItem(Icons.logout, 'Logout', mainColor, () async {
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
                  Navigator.pop(scaffoldContext);
                  Navigator.pushReplacement(
                    scaffoldContext,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
