// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../screens/home_admin.dart';
// import '../screens/home_customer.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> loginUser(BuildContext context, String email, String password) async {
//     try {
//       final UserCredential result = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       final User? user = result.user;
//       if (user == null) {
//         _showError(context, "Login gagal. User tidak ditemukan.");
//         return;
//       }
//
//       final DocumentSnapshot snapshot =
//       await _firestore.collection('users').doc(user.uid).get();
//
//       if (!snapshot.exists) {
//         // Jika user belum pernah login sebelumnya, buat sebagai customer
//         await _firestore.collection('users').doc(user.uid).set({
//           'uid': user.uid,
//           'email': user.email,
//           'name': user.displayName ?? '',
//           'role': 'customer',
//         });
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) =>  HomeCustomer()),
//         );
//         return;
//       }
//
//       final String role = snapshot.get('role');
//       if (role == 'admin') {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) =>  HomeAdmin()),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) =>  HomeCustomer()),
//         );
//       }
//     } catch (e) {
//       _showError(context, "Login gagal: ${e.toString()}");
//     }
//   }
//
//   void _showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }
// }
