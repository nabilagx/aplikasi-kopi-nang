import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer/home_customer.dart';
import 'home_admin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


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

      // Login ke Firebase
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // Ambil idToken Firebase
      final idToken = await user.getIdToken();

      // Kirim ke backend ASP.NET buat dapat JWT
      final response = await http.post(
        Uri.parse("https://kopinang-api-production.up.railway.app/api/Auth/firebase-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)["token"];

        // Simpan JWT ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt", token);

        print("JWT berhasil disimpan: $token");
        print("nih idtoken:  $idToken");
      } else {
        print("Gagal dapat JWT: ${response.body}");
      }

      return user;
    } catch (e) {
      print("Error saat login: $e");
      return null;
    }
  }


  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
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
      final inviteQuery = await inviteRef
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (inviteQuery.docs.isEmpty) {
        _showError(
            context, "Data admin tidak ditemukan. Hubungi administrator.");
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_login.gif',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4), // biar teks kelihatan
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 175,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Selamat Datang di KOPI NANG",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person, color: Colors.white),
                    label: const Text("Login sebagai Customer"),
                    onPressed: () => loginCustomer(context),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    label: const Text("Login sebagai Admin"),
                    onPressed: () => loginAdmin(context),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D47A1),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF0D47A1)),
                      ),
                    ),
                    icon: const Icon(Icons.app_registration, color: Color(0xFF0D47A1)),
                    label: const Text("Register Customer"),
                    onPressed: () => loginCustomer(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}