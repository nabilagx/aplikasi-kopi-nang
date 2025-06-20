import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/customer_bottom_nav.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';

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
  final String? adminReply;

  UlasanModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    required this.review,
    this.adminReply,
  });

  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      id: json['id'],
      orderId: json['orderId'],
      userId: json['userId'],
      rating: json['rating'],
      review: json['review'],
      adminReply: json['adminReply'],
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
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('User belum login');
    }

    final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Order/user/$uid');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat pesanan (${response.statusCode})');
    }
  }


  Future<List<OrderModel>> getUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User belum login");
    return await fetchOrdersByUid(user.uid);
  }

  Future<List<UlasanModel>> fetchUlasanByOrderId(int orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('User belum login');
    }

    final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Ulasan/order/$orderId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => UlasanModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat ulasan (${response.statusCode})');
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
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('User belum login');
    }

    final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Ulasan');
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'id': 0,
      'orderId': orderId,
      'userId': userId,
      'rating': rating,
      'review': review,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      showKopiNangAlert(
        context,
        "Ulasan Berhasil",
        "Ulasan berhasil dikirim",
        type: 'success',
      );

      // Refresh ulasan
      final updatedUlasan = await fetchUlasanByOrderId(orderId);
      if (mounted) {
        setState(() {
          ulasanPerOrder[orderId] = updatedUlasan;
          futureOrders = getUserOrders();
        });
      }
    } else {
      if (!mounted) return;
      showKopiNangAlert(
        context,
        "Gagal",
        "Gagal mengirim ulasan: ${response.statusCode}",
        type: 'error',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            "Beri Ulasan",
            style: TextStyle(
              color: Color(0xFF0D47A1),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rating:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setStateDialog(() {
                      selectedRating = starIndex;
                    });
                  },
                  child: Icon(
                    starIndex <= selectedRating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              decoration: InputDecoration(
                labelText: 'Tulis ulasan',
                labelStyle: const TextStyle(color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D47A1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              if (reviewController.text.trim().isEmpty) {
                showKopiNangAlert(
                  context,
                  "Peringatan",
                  "Ulasan tidak boleh kosong",
                  type: 'warning',
                );
                return;
              }

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Center(
                    child: Text(
                      'Konfirmasi',
                      style: TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  content: const Text('Apakah kamu yakin ingin mengirim ulasan?'),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  actions: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              Navigator.pop(context); // tutup dialog utama

              await kirimUlasan(
                orderId: orderId,
                userId: userId,
                rating: selectedRating,
                review: reviewController.text,
              );

              showKopiNangAlert(
                context,
                "Ulasan Dikirim",
                "Ulasan berhasil dikirim",
                type: 'success',
              );

            },
            child: const Text("Kirim"),
          ),
        ],
      ),
      )
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Riwayat Pesanan'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
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
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 0),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pesanan #${order.id} - ${order.status}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
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
                      if (order.status == "Diproses" || order.status == "Selesai" || order.status == "Siap") ...[
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

                                      if (ulasan.adminReply != null && ulasan.adminReply!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 8, left: 12),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD), // biru muda dari palet biru
                                            border: const Border(
                                              left: BorderSide(color: Color(0xFF0D47A1), width: 4),
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Balasan Admin:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ulasan.adminReply!,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                ),
                          ),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code, color: Colors.white),
                              label: const Text(
                                "Lihat QR Code",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(20),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/logo.png',
                                          height: 60,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "Tunjukkan QR Code ini ke kasir",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D47A1),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: order.qrCode != null
                                              ? Image.network(
                                            order.qrCode!,
                                            height: 180,
                                            width: 180,
                                          )
                                              : const Text("QR Code tidak tersedia."),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.check, color: Colors.white),
                                            label: const Text("Tutup", style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0D47A1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),


                            ElevatedButton(
                              onPressed: (order.status == "Selesai" && !hasUlasan)
                                  ? () => showUlasanDialog(order.id, order.userId)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (order.status == "Selesai" && !hasUlasan)
                                    ? const Color(0xFF0D47A1)
                                    : Colors.grey.shade400,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Beri Ulasan", style: TextStyle(color: Colors.white)),
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


