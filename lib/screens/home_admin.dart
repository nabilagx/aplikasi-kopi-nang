import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({Key? key}) : super(key: key);

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int ordersToday = 0;
  int totalUsers = 0;
  String topProduct = '-';
  int newReviews = 0;
  List<Map<String, dynamic>> latestReviews = [];
  bool isLoading = false;

  // Contoh data penjualan mingguan untuk grafik batang
  List<BarChartGroupData> barChartData = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<int> fetchTotalCustomers() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .get();
    return querySnapshot.docs.length;
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ordersRes = await http.get(Uri.parse('http://192.168.1.7/api/Order'));
      final ulasanRes = await http.get(Uri.parse('http://192.168.1.7/api/Ulasan'));
      final produkRes = await http.get(Uri.parse('http://192.168.1.7/api/Produk'));

      if (ordersRes.statusCode == 200) {
        final List<dynamic> orders = json.decode(ordersRes.body);
        final today = DateTime.now();
        ordersToday = orders.where((o) {
          final date = DateTime.parse(o['createdAt']);
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        // Generate data penjualan mingguan untuk grafik
        barChartData = generateBarChartData(orders);
      }

      if (ulasanRes.statusCode == 200) {
        final List<dynamic> ulasan = json.decode(ulasanRes.body);
        latestReviews =
            ulasan.reversed.take(5).map((e) => e as Map<String, dynamic>).toList();
        newReviews = latestReviews.length;
      }

      if (produkRes.statusCode == 200) {
        final List<dynamic> produk = json.decode(produkRes.body);
        if (produk.isNotEmpty) {
          topProduct = produk.first['namaProduk'];
        }
      }

      totalUsers = await fetchTotalCustomers();
    } catch (e) {
      debugPrint('Error fetchDashboardData: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  // Fungsi untuk generate data grafik batang penjualan 7 hari terakhir
  List<BarChartGroupData> generateBarChartData(List<dynamic> orders) {
    final now = DateTime.now();
    Map<int, int> salesByDay = {}; // key = weekday (1=Mon,..7=Sun), value = count

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      salesByDay[day.weekday] = 0;
    }

    for (var order in orders) {
      final date = DateTime.parse(order['createdAt']);
      final diff = now.difference(date).inDays;
      if (diff < 7) {
        salesByDay[date.weekday] = (salesByDay[date.weekday] ?? 0) + 1;
      }
    }

    // Buat list BarChartGroupData dari Senin (1) sampai Minggu (7)
    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: salesByDay[i]?.toDouble() ?? 0,
              color: Colors.blue,
              width: 18,
              borderRadius: BorderRadius.circular(6),
            )
          ],
        ),
      );
    }
    return barGroups;
  }

  // Widget judul hari (Sen, Sel, Rab, ...)
  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    String text = '';
    if (value >= 1 && value <= 7) {
      text = days[value.toInt() - 1];
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(text, style: style),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin KOPI NANG'),
        backgroundColor: Colors.blue[800],
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCard("📦", "Pesanan Hari Ini", ordersToday.toString()),
                  _buildCard("🧑", "User Terdaftar", totalUsers.toString()),
                  _buildCard("☕", "Produk Terlaris", topProduct),
                  _buildCard("🌟", "Ulasan Baru", newReviews.toString()),
                ],
              ),
              const SizedBox(height: 24),
              const Text("📊 Grafik Penjualan Mingguan",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    maxY: 10,
                    barGroups: barChartData,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: bottomTitles,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("📝 Ulasan Terbaru",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...latestReviews.map((review) => Card(
                child: ListTile(
                  title: Text("Order ID: ${review['orderId']}"),
                  subtitle: Text(
                      "${review['review'] ?? '-'}\nBalasan: ${review['adminReply'] ?? '-'}"),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String icon, String label, String value) {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            Text(label,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
