import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_admin.dart';
import 'screens/customer/home_customer.dart';
import 'screens/customer/cart_provider.dart'; // tambahkan ini

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'KOPI NANG',
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          final uid = authSnapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future:
            FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final role = userSnapshot.data!['role'];
                if (role == 'admin') {
                  return const HomeAdmin();
                } else if (role == 'customer') {
                  return const HomeCustomer();
                } else {
                  return Scaffold(
                    body: Center(child: Text("Role tidak dikenali: $role")),
                  );
                }
              } else {
                return const Scaffold(
                  body: Center(child: Text("Data user tidak ditemukan")),
                );
              }
            },
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
