import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kopinang/widgets/drawer_admin.dart';

class UlasanModel {
  final int id;
  final int orderId;
  final String userId;
  final int rating;
  final String? review;
  String? adminReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  UlasanModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    this.review,
    this.adminReply,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      id: json['id'],
      orderId: json['orderId'],
      userId: json['userId'],
      rating: json['rating'],
      review: json['review'],
      adminReply: json['adminReply'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class KelolaUlasanPage extends StatefulWidget {
  const KelolaUlasanPage({Key? key}) : super(key: key);

  @override
  State<KelolaUlasanPage> createState() => _KelolaUlasanPageState();
}

class _KelolaUlasanPageState extends State<KelolaUlasanPage> {
  late Future<List<UlasanModel>> futureUlasan;

  @override
  void initState() {
    super.initState();
    futureUlasan = fetchUlasan();
  }

  Future<List<UlasanModel>> fetchUlasan() async {
    final url = Uri.parse('http://192.168.1.7/api/Ulasan');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => UlasanModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat ulasan');
    }
  }

  Future<void> updateAdminReply(int ulasanId, String reply) async {
    final url = Uri.parse('http://192.168.1.7/api/Ulasan/$ulasanId');
    final body = json.encode({
      'adminReply': reply,
      //
    });

    final headers = {'Content-Type': 'application/json'};

    final response = await http.patch(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balasan admin berhasil disimpan')),
      );
      setState(() {
        futureUlasan = fetchUlasan();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan balasan: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Ulasan')),
      drawer: DrawerAdmin(scaffoldContext: context),
      body: FutureBuilder<List<UlasanModel>>(
        future: futureUlasan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada ulasan'));
          }

          final ulasanList = snapshot.data!;
          return ListView.builder(
            itemCount: ulasanList.length,
            itemBuilder: (context, index) {
              final ulasan = ulasanList[index];
              final TextEditingController replyController =
              TextEditingController(text: ulasan.adminReply ?? '');

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order ID: ${ulasan.orderId}"),
                      Text("User ID: ${ulasan.userId}"),
                      Row(
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < ulasan.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Review: ${ulasan.review ?? '-'}"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: replyController,
                        decoration: const InputDecoration(
                          labelText: 'Balasan Admin',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        enabled: ulasan.adminReply == null || ulasan.adminReply!.isEmpty, // hanya aktif jika belum dibalas
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: (ulasan.adminReply == null || ulasan.adminReply!.isEmpty)
                              ? () {
                            final newReply = replyController.text.trim();
                            updateAdminReply(ulasan.id, newReply);
                          }
                              : null, // disable tombol jika sudah ada balasan
                          child: const Text('Simpan Balasan'),
                        ),
                      ),
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
