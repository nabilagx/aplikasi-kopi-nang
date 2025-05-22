import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_screen.dart';
import '../../widgets/customer_bottom_nav.dart'; // import ini penting!

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
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user.photoURL ?? ''),
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 16),
              Text("Nama: ${user.displayName ?? '-'}"),
              Text("Email: ${user.email ?? '-'}"),
              const SizedBox(height: 32),
            ],
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
