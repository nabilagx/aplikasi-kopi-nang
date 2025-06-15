import 'package:flutter/material.dart';
import '../screens/customer/home_customer.dart';
import '../screens/customer/order_detail_screen.dart';
// import 'pesanan_customer.dart';
// import 'riwayat_customer.dart';
import '../screens/customer/profil_customer.dart';
import '../screens/customer/order_history_page.dart';

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
      case 1:
        destination = const OrderHistoryPage();
        break;
      case 2:
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.blueGrey.shade300,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Beranda",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: "Riwayat",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profil",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
