import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/customer_bottom_nav.dart';

class OrderDetailModel {
  final int id;
  final int orderId;
  final int produkId;
  final int jumlah;
  final int hargaSatuan;

  OrderDetailModel({
    required this.id,
    required this.orderId,
    required this.produkId,
    required this.jumlah,
    required this.hargaSatuan,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'],
      orderId: json['orderId'],
      produkId: json['produkId'],
      jumlah: json['jumlah'],
      hargaSatuan: json['hargaSatuan'],
    );
  }
}

class OrderModel {
  final int id;
  final String userId;
  final int totalHarga;
  final String status;
  final String metodePembayaran;
  final String? buktiPembayaran;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? qrCode;
  final List<OrderDetailModel> orderDetails;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalHarga,
    required this.status,
    required this.metodePembayaran,
    this.buktiPembayaran,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.qrCode,
    required this.orderDetails,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['userId'],
      totalHarga: json['totalHarga'],
      status: json['status'],
      metodePembayaran: json['metodePembayaran'],
      buktiPembayaran: json['buktiPembayaran'] as String?,
      latitude: (json['latitude'] != null) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] != null) ? (json['longitude'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      qrCode: json['qrCode'] as String?,
      orderDetails: (json['orderDetails'] as List)
          .map((e) => OrderDetailModel.fromJson(e))
          .toList(),
    );
  }
}

class UlasanModel {
  final int id;
  final int orderId;
  final String userId;
  final int rating;
  final String review;

  UlasanModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    required this.review,
  });

  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      id: json['id'],
      orderId: json['orderId'],
      userId: json['userId'],
      rating: json['rating'],
      review: json['review'],
    );
  }
}

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<OrderModel>> futureOrders;

  // Simpan ulasan per orderId
  Map<int, List<UlasanModel>> ulasanPerOrder = {};

  Future<List<OrderModel>> fetchOrdersByUid(String uid) async {
    final url = Uri.parse('http://192.168.1.7/api/Order/user/$uid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat pesanan');
    }
  }

  Future<List<OrderModel>> getUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User belum login");
    return await fetchOrdersByUid(user.uid);
  }

  Future<List<UlasanModel>> fetchUlasanByOrderId(int orderId) async {
    final url = Uri.parse('http://192.168.1.7/api/Ulasan/order/$orderId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => UlasanModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat ulasan');
    }
  }

  Future<void> fetchAllUlasan(List<OrderModel> orders) async {
    for (var order in orders) {
      try {
        final ulasanList = await fetchUlasanByOrderId(order.id);
        ulasanPerOrder[order.id] = ulasanList;
      } catch (e) {
        ulasanPerOrder[order.id] = [];
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> kirimUlasan({
    required int orderId,
    required String userId,
    required int rating,
    required String review,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final url = Uri.parse('http://192.168.1.7/api/Ulasan');
    final body = json.encode({
      'id': 0,
      'orderId': orderId,
      'userId': userId,
      'rating': rating,
      'review': review,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });

    final headers = {'Content-Type': 'application/json-patch+json'};

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan berhasil dikirim')),
      );

      // Refresh ulasan untuk order tersebut
      final updatedUlasan = await fetchUlasanByOrderId(orderId);
      setState(() {
        ulasanPerOrder[orderId] = updatedUlasan;
        futureOrders = getUserOrders(); // Jika mau refresh list pesanan juga
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim ulasan: ${response.statusCode}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    futureOrders = getUserOrders();
    futureOrders.then((orders) {
      fetchAllUlasan(orders);
    });
  }

  void showUlasanDialog(int orderId, String userId) {
    int selectedRating = 5;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Beri Ulasan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rating:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(labelText: 'Tulis ulasan'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ulasan tidak boleh kosong')),
                  );
                  return;
                }

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah kamu yakin ingin mengirim ulasan?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Ya'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                Navigator.pop(context); // tutup dialog

                await kirimUlasan(
                  orderId: orderId,
                  userId: userId,
                  rating: selectedRating,
                  review: reviewController.text,
                );
              },
              child: const Text("Kirim"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
      body: FutureBuilder<List<OrderModel>>(
        future: futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pesanan'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final ulasanList = ulasanPerOrder[order.id] ?? [];
              final hasUlasan = ulasanList.isNotEmpty;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pesanan #${order.id} - ${order.status}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Total: Rp${order.totalHarga}"),
                      Text("Metode: ${order.metodePembayaran}"),
                      Text("Tanggal: ${order.createdAt.toLocal()}"),
                      const Divider(),
                      const Text("Detail Produk:"),
                      ...order.orderDetails.map(
                            (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            "Produk ID: ${item.produkId}, Qty: ${item.jumlah}, Harga: Rp${item.hargaSatuan}",
                          ),
                        ),
                      ),
                      if (order.status == "Selesai") ...[
                        const SizedBox(height: 8),

                        // Preview ulasan jika ada
                        if (hasUlasan) ...[
                          const Text("Ulasan Anda:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...ulasanList.map(
                                (ulasan) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                          (i) => Icon(
                                        i < ulasan.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(ulasan.review),
                                ],
                              ),
                            ),
                          ),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code),
                              label: const Text("Lihat QR Code"),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("QR Code Pesanan"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (order.qrCode != null)
                                          Image.network(order.qrCode!)
                                        else
                                          const Text("QR Code tidak tersedia."),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Tutup"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            ElevatedButton(
                              onPressed: hasUlasan
                                  ? null
                                  : () {
                                showUlasanDialog(order.id, order.userId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                hasUlasan ? Colors.grey : null,
                              ),
                              child: const Text("Beri Ulasan"),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
