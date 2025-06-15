import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../login_screen.dart';
import '../../widgets/customer_bottom_nav.dart';

class ProfilCustomer extends StatelessWidget {
  const ProfilCustomer({super.key});

  Future<void> _logout(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await FirebaseAuth.instance.signOut();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  LoginScreen()),
          (route) => false,
    );
  }

  void _hubungiAdmin() async {
    final url = Uri.parse(
      "https://wa.me/6281231915747?text=Halo%20Admin%20KOPI%20NANG%2C%20saya%20ingin%20bertanya%20tentang%20pesanan%20saya.",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak dapat membuka WhatsApp.';
    }
  }

  void _bukaPedoman(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // agar efek transparan di luar card
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, // card putih
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 60,
              ),
              const SizedBox(height: 16),

              const Text(
                'Pedoman Aplikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Isi Pedoman
              const Text(
                "1. Pilih menu favorit Anda.\n"
                    "2. Checkout dan lakukan pembayaran.\n"
                    "3. Tunjukkan QR saat pengambilan pesanan.\n"
                    "4. Beri ulasan untuk pengalaman Anda.\n\n"
                    "Jika mengalami kendala, hubungi admin.",
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.left,
              ),

              const SizedBox(height: 24),

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user?.photoURL ?? ''),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.displayName ?? 'Pengguna',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            _buildProfileButton(
              icon: Icons.phone,
              label: "Hubungi Admin",
              color: Colors.green,
              onTap: _hubungiAdmin,
            ),
            const SizedBox(height: 12),
            _buildProfileButton(
              icon: Icons.menu_book,
              label: "Pedoman Aplikasi",
              color: Colors.blue,
              onTap: () => _bukaPedoman(context),
            ),
            const SizedBox(height: 12),
            _buildProfileButton(
              icon: Icons.logout,
              label: "Logout",
              color: Colors.red,
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 40),
            Text(
              "© 2025 KOPI NANG",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
