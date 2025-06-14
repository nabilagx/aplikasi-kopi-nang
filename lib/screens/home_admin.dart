import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:kopinang/widgets/drawer_admin.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  List<dynamic> orders = [];
  int totalPemasukan = 0;
  int totalPesanan = 0;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final response = await http.get(Uri.parse('https://kopinang-api-production.up.railway.app/api/Order'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final now = DateTime.now();
      final todayOrders = data.where((order) {
        final orderDate = DateTime.parse(order['createdAt']);
        return orderDate.year == now.year &&
            orderDate.month == now.month &&
            orderDate.day == now.day &&
            order['status'] == 'Selesai';
      }).toList();

      final pemasukan = todayOrders.fold<int>(
        0,
            (sum, order) => sum + (order['totalHarga'] as num).toInt(),
      );

      setState(() {
        orders = todayOrders;
        totalPesanan = todayOrders.length;
        totalPemasukan = pemasukan;
      });
    } else {
      print('Failed to fetch orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        title: const Text('Dashboard Admin - KOPI NANG'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      drawer: DrawerAdmin(scaffoldContext: context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Total Pesanan Hari Ini',
                    value: totalPesanan.toString(),
                    icon: Icons.local_cafe,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: 'Total Pemasukan Hari Ini',
                    value: currencyFormatter.format(totalPemasukan),
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Pesanan Hari Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Belum ada pesanan hari ini'))
                  : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text('Pesanan #${order['id']}'),
                      subtitle: Text('Total: ${currencyFormatter.format(order['totalHarga'])}'),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF0D47A1)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
