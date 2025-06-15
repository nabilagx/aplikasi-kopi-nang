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
    final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Ulasan');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((e) => UlasanModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat ulasan');
    }
  }

  Future<void> updateAdminReply(int ulasanId, String reply) async {
    final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Ulasan/$ulasanId');
    final body = json.encode({
      'adminReply': reply,
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
    const Color navy = Color(0xFF0D47A1);
    const Color softBlue = Color(0xFFEAF4FB);

    return Scaffold(
      backgroundColor: softBlue,
      appBar: AppBar(
        title: const Text('Kelola Ulasan & Rating'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
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
                color: Colors.white,
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order ID: ${ulasan.orderId}", style: TextStyle(color: navy)),
                      Text("User ID: ${ulasan.userId}", style: TextStyle(color: navy)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < ulasan.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("Review: ${ulasan.review ?? '-'}"),
                      const SizedBox(height: 10),
                      TextField(
                        controller: replyController,
                        decoration: InputDecoration(
                          labelText: 'Balasan Admin',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: softBlue,
                        ),
                        maxLines: 3,
                        enabled: ulasan.adminReply == null || ulasan.adminReply!.isEmpty,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: (ulasan.adminReply == null || ulasan.adminReply!.isEmpty)
                              ? () {
                            final newReply = replyController.text.trim();
                            updateAdminReply(ulasan.id, newReply);
                          }
                              : null,
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
