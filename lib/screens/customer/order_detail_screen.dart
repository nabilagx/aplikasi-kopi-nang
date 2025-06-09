import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/customer_bottom_nav.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? order;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrder();
  }

  Future<void> fetchOrder() async {
    try {
      final url = 'http://192.168.1.7/api/Order/${widget.orderId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          order = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat detail order")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (order == null) return const Scaffold(body: Center(child: Text("Order tidak ditemukan")));

    final orderDetails = order!['orderDetails'] as List;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🧾 ID Pesanan: ${order!['id']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🟡 Status: ${order!['status']}", style: const TextStyle(fontSize: 16)),
            Text("💰 Total Harga: Rp${order!['totalHarga']}", style: const TextStyle(fontSize: 16)),
            Text("💳 Metode Pembayaran: ${order!['metodePembayaran']}"),
            const Divider(height: 32),

            const Text("📦 Detail Produk:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...orderDetails.map((item) {
              final produk = item['produk'];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(produk != null ? produk['nama'] : "Produk tidak ditemukan"),
                  subtitle: Text("Jumlah: ${item['jumlah']}"),
                  trailing: Text("Rp${item['hargaSatuan']}"),
                ),
              );
            }),

            const SizedBox(height: 24),
            const Text("🔐 QR Code untuk Verifikasi:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                data: "kopinang://order/${order!['id']}",
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Tunjukkan QR ini ke admin untuk menyelesaikan pesanan.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
