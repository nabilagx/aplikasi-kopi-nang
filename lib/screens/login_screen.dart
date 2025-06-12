import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer/home_customer.dart';
import 'home_admin.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDocRef.get();

    if (!snapshot.exists) {
      // Buat data user baru
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'role': 'customer',
        'name': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
      });

      // Cek ulang data setelah dibuat
      final newSnapshot = await userDocRef.get();
      final data = newSnapshot.data();

      if (data == null) {
        _showError(context, "Data user tidak ditemukan");
        return;
      }
    }

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

    final usersRef = _firestore.collection('users');
    final inviteRef = _firestore.collection('invite');

    final userDoc = await usersRef.doc(user.uid).get();

    if (!userDoc.exists) {
      // Belum ada di users, cek email di invite collection
      final inviteQuery = await inviteRef.where('email', isEqualTo: user.email).limit(1).get();

      if (inviteQuery.docs.isEmpty) {
        _showError(context, "Data admin tidak ditemukan. Hubungi administrator.");
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        return;
      }

      // Ada di invite, tambahkan ke users dengan role admin
      await usersRef.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
        'role': 'admin',
      });

      // Hapus data invite
      await inviteRef.doc(inviteQuery.docs.first.id).delete();
    } else {
      final data = userDoc.data()!;
      if (data['role'] != 'admin') {
        _showError(context, "Akses admin ditolak. Anda bukan admin.");
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardAdminPage()),
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
