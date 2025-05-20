import 'package:flutter/material.dart';

class HomeCustomer extends StatelessWidget {
  const HomeCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Home")),
      body: const Center(child: Text("Selamat datang, Customer!")),
    );
  }
}
