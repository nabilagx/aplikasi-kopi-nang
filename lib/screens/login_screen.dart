import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_customer.dart';
import 'home_admin.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> _signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // Bisa log error di sini kalau perlu
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> loginCustomer(BuildContext context) async {
    final user = await _signInWithGoogle();
    if (user == null) {
      _showError(context, "Login gagal atau dibatalkan");
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // Buat data user baru dengan role customer saat register/login pertama kali
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': 'customer',
      });
    }

    // Langsung masuk ke halaman customer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeCustomer()),
    );
  }

  Future<void> loginAdmin(BuildContext context) async {
    final user = await _signInWithGoogle();
    if (user == null) {
      _showError(context, "Login gagal atau dibatalkan");
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      _showError(context, "Data admin tidak ditemukan. Hubungi administrator.");
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      return;
    }

    final data = snapshot.data();
    if (data == null || data['role'] != 'admin') {
      _showError(context, "Akses admin ditolak. Anda bukan admin.");
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeAdmin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login KOPI NANG")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Login sebagai Customer"),
              onPressed: () => loginCustomer(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text("Login sebagai Admin"),
              onPressed: () => loginAdmin(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.app_registration),
              label: const Text("Register Customer"),
              onPressed: () => loginCustomer(context),
            ),
          ],
        ),
      ),
    );
  }
}
