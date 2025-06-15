import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kopinang/widgets/drawer_admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AppUser {
  final String uid;
  final String nama;

  AppUser({required this.uid, required this.nama});
}

class Produk {
  final int id;
  final String nama;

  Produk({required this.id, required this.nama});

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'],
      nama: json['nama'],
    );
  }
}

class OrderDetail {
  final int id;
  final int orderId;
  final int produkId;
  final int jumlah;
  final int hargaSatuan;

  OrderDetail({
    required this.id,
    required this.orderId,
    required this.produkId,
    required this.jumlah,
    required this.hargaSatuan,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'],
      orderId: json['orderId'],
      produkId: json['produkId'],
      jumlah: json['jumlah'],
      hargaSatuan: json['hargaSatuan'],
    );
  }
}

class Order {
  final int id;
  final String userId;
  final int totalHarga;
  String status;
  final String metodePembayaran;
  final String buktiPembayaran;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String qrCode;
  final List<OrderDetail> orderDetails;

  Order({
    required this.id,
    required this.userId,
    required this.totalHarga,
    required this.status,
    required this.metodePembayaran,
    required this.buktiPembayaran,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.qrCode,
    required this.orderDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      totalHarga: json['totalHarga'],
      status: json['status'],
      metodePembayaran: json['metodePembayaran'],
      buktiPembayaran: json['buktiPembayaran'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      qrCode: json['qrCode'],
      orderDetails: (json['orderDetails'] as List)
          .map((e) => OrderDetail.fromJson(e))
          .toList(),
    );
  }
}

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  List<Order> orders = [];
  List<Produk> allProduk = [];
  bool _isLoading = true;
  bool _hasError = false;

  Map<String, String> userIdToNama = {};


  final List<String> statusList = ['Diproses', 'Ditolak', 'Siap'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await fetchAllProduk();
    await fetchFirebaseUsers();
    print('>> SELESAI FETCH USER, lanjut fetch orders...');
    await fetchOrders();
  }



  Future<void> fetchAllProduk() async {
    try {
      final response = await http.get(Uri.parse('https://kopinang-api-production.up.railway.app/api/Produk'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        allProduk = data.map((e) => Produk.fromJson(e)).toList();
      } else {
        throw Exception('Gagal mengambil produk');
      }
    } catch (e) {
      _hasError = true;
    }
  }

  Future<void> fetchFirebaseUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      final uid = doc.id;
      final nama = data['name'] ?? 'Tidak diketahui';

      print('>> Firebase User: $uid => $nama'); // Tambah ini

      return AppUser(
        uid: uid,
        nama: nama,
      );
    }).toList();

    setState(() {
      userIdToNama = { for (var user in users) user.uid: user.nama };
      print('>> userIdToNama map: $userIdToNama'); // Tambah ini
    });
  }



  Future<void> fetchOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('https://kopinang-api-production.up.railway.app/api/Order'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data.map((e) => Order.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> updateStatus(int orderId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('https://kopinang-api-production.up.railway.app/api/Order/$orderId/status'),
        headers: {'Content-Type': 'application/json-patch+json'},
        body: jsonEncode(newStatus),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diperbarui')),
        );
        fetchOrders(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error memperbarui status')),
      );
    }
  }

  String getNamaProdukById(int id) {
    final produk = allProduk.firstWhere(
          (p) => p.id == id,
      orElse: () => Produk(id: id, nama: 'Produk tidak ditemukan'),
    );
    return produk.nama;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Pesanan'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFEAF4FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Pesanan'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFEAF4FB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Gagal memuat data pesanan',
                  style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  fetchAllProduk().then((_) => fetchOrders());
                },
                child: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEAF4FB),
      drawer: DrawerAdmin(
        onSelectMenu: (menu) {
          Navigator.pop(context);
        },
        scaffoldContext: context,
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            color: Colors.white,
            shadowColor: Colors.black26,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('User: ${userIdToNama[order.userId] ?? order.userId}',
                      style: const TextStyle(color: Colors.black54)),
                  Text('Total: Rp${order.totalHarga}',
                      style: const TextStyle(color: Colors.black87)),
                  Text('Metode: ${order.metodePembayaran}',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  const Text('Detail Produk:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                  ...order.orderDetails.map((detail) {
                    final namaProduk = getNamaProdukById(detail.produkId);
                    return Text('- $namaProduk x${detail.jumlah}',
                        style: const TextStyle(color: Colors.black87));
                  }).toList(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      order.status.toLowerCase() == 'selesai'
                          ? const Text(
                        'Selesai',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      )
                          : DropdownButton<String>(
                        value: statusList.contains(order.status)
                            ? order.status
                            : null,
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != order.status) {
                            updateStatus(order.id, newValue);
                          }
                        },
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        iconEnabledColor: const Color(0xFF0D47A1),
                        items: statusList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
