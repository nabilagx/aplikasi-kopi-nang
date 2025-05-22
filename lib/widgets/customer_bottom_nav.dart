import 'package:flutter/material.dart';
import 'home_customer.dart';
// import 'pesanan_customer.dart';
// import 'riwayat_customer.dart';
import 'profil_customer.dart';

class CustomerBottomNav extends StatefulWidget {
  final int currentIndex;

  const CustomerBottomNav({super.key, required this.currentIndex});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeCustomer();
        break;
      // case 1:
      //   destination = const PesananCustomer();
      //   break;
      // case 2:
      //   destination = const RiwayatCustomer();
      //   break;
      case 3:
      destination = const ProfilCustomer();
        break;
      default:
        destination = const HomeCustomer();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blue.shade700,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Pesanan"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ],
    );
  }
}
