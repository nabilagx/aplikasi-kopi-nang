import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_provider.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';

class DetailMenuScreen extends StatefulWidget {
  final Map<String, dynamic> menuData;

  const DetailMenuScreen({super.key, required this.menuData});

  @override
  State<DetailMenuScreen> createState() => _DetailMenuScreenState();
}

class _DetailMenuScreenState extends State<DetailMenuScreen> {
  late Future<List<Map<String, dynamic>>> futureReviews;

  @override
  void initState() {
    super.initState();
    futureReviews = fetchReviews(widget.menuData['id']);
  }

  Future<List<Map<String, dynamic>>> fetchReviews(int produkId) async {
    final resp = await http.get(Uri.parse('https://kopinang-api-production.up.railway.app/api/Ulasan'));
    if (resp.statusCode != 200) throw Exception();
    final List reviews = json.decode(resp.body);
    final List<Map<String, dynamic>> result = [];

    for (var r in reviews) {
      final orderResp = await http.get(
          Uri.parse('https://kopinang-api-production.up.railway.app/api/Order/${r['orderId']}'));
      if (orderResp.statusCode != 200) continue;
      final order = json.decode(orderResp.body);
      final details = order['orderDetails'] as List;
      if (details.any((d) => d['produkId'] == produkId)) {
        result.add({
          'rating': r['rating'],
          'review': r['review'],
          'adminReply': r['adminReply'],
          'userId': r['userId'],
          'userName': r['userName'] ?? 'Customer',
        });
      }
    }

    return result.take(3).toList();
  }

  double getAverageRating(List<Map<String, dynamic>> ulasanList) {
    if (ulasanList.isEmpty) return 0.0;
    double total = 0;
    for (var ulasan in ulasanList) {
      total += (ulasan['rating'] ?? 0).toDouble();
    }
    return total / ulasanList.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text(widget.menuData['nama'] ?? 'Detail Produk'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureReviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat ulasan.'));
          }

          final reviews = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.menuData['gambar'] ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.menuData['nama'] ?? 'Tanpa Nama',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${widget.menuData['harga']?.toString() ?? '0'}',
                            style: const TextStyle(fontSize: 20, color: Color(0xFF0D47A1)),
                          ),
                        ],
                      ),
                    ),
                    if (snapshot.hasData && snapshot.data!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                getAverageRating(snapshot.data!).toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, size: 28, color: Colors.amber),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rating',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.menuData['deskripsi'] ?? 'Tidak ada deskripsi.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Ulasan Pelanggan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 8),

                if (reviews.isEmpty)
                  const Text('Belum ada ulasan untuk produk ini.')
                else
                  ...reviews.map((ulasan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: const Color(0xFFEAF4FB),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ulasan['userName'] ?? 'Customer',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                        (index) => Icon(
                                      index < ulasan['rating'] ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ulasan['review'] ?? '',
                              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                            ),
                            if ((ulasan['adminReply'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9EAFB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.reply, size: 16, color: Color(0xFF0D47A1)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        ulasan['adminReply'],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )),
                if (reviews.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // modal ulasan lengkap
                      },
                      child: const Text('Lihat Semua Ulasan'),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          onPressed: () {
            Provider.of<CartProvider>(context, listen: false)
                .addItem(widget.menuData);
            showKopiNangAlert(context, "Berhasil", "Produk ditambahkan ke keranjang");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Tambah ke Keranjang"),
        ),
      ),
    );
  }
}
