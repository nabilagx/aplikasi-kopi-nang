import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:kopinang/widgets/drawer_admin.dart';

class LaporanPenjualanPage extends StatefulWidget {
  const LaporanPenjualanPage({Key? key}) : super(key: key);

  @override
  _LaporanPenjualanPageState createState() => _LaporanPenjualanPageState();
}

class _LaporanPenjualanPageState extends State<LaporanPenjualanPage> {
  List<dynamic> orders = [];
  bool loading = false;

  DateTime? filterDate;
  int? filterMonth;
  int? filterYear;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      if (idToken == null) {
        _showMessage('User belum login');
        setState(() => loading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('https://kopinang-api-production.up.railway.app/api/Order'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = (data as List)
              .where((o) => o['status'] == 'Selesai')
              .toList();
        });
      } else {
        _showMessage('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error mengambil data: $e');
    }

    setState(() => loading = false);
  }


  List<dynamic> get filteredOrders {
    return orders.where((order) {
      try {
        final createdAt = DateTime.parse(order['createdAt'].toString());
        if (filterDate != null) {
          return createdAt.year == filterDate!.year &&
              createdAt.month == filterDate!.month &&
              createdAt.day == filterDate!.day;
        } else if (filterMonth != null && filterYear != null) {
          return createdAt.year == filterYear! && createdAt.month == filterMonth!;
        } else if (filterYear != null) {
          return createdAt.year == filterYear!;
        }
        return true;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> pickFilterDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: filterDate ?? now,
      firstDate: DateTime(2023),
      lastDate: now,
      helpText: 'Pilih Tanggal',
    );
    if (picked != null) {
      setState(() {
        filterDate = picked;
        filterMonth = null;
        filterYear = null;
      });
    }
  }

  Future<void> pickFilterMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(filterYear ?? now.year, filterMonth ?? now.month),
      firstDate: DateTime(2023),
      lastDate: now,
      helpText: 'Pilih Bulan (abaikan tanggal)',
    );
    if (picked != null) {
      setState(() {
        filterMonth = picked.month;
        filterYear = picked.year;
        filterDate = null;
      });
    }
  }

  Future<void> pickFilterYear() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(filterYear ?? now.year),
      firstDate: DateTime(2023),
      lastDate: now,
      helpText: 'Pilih Tahun (abaikan bulan dan tanggal)',
    );
    if (picked != null) {
      setState(() {
        filterYear = picked.year;
        filterMonth = null;
        filterDate = null;
      });
    }
  }

  Future<void> exportToExcel() async {
    if (filteredOrders.isEmpty) {
      _showMessage('Tidak ada data untuk diekspor');
      return;
    }

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      _showMessage('Izin penyimpanan diperlukan');
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['LaporanPenjualan'];

    // Header kolom
    sheet.appendRow([
      TextCellValue('ID Order'),
      TextCellValue('User ID'),
      TextCellValue('Total Harga'),
      TextCellValue('Status'),
      TextCellValue('Metode Pembayaran'),
      TextCellValue('Tanggal Pesan'),
    ]);


    for (var order in filteredOrders) {
      sheet.appendRow([
        IntCellValue(order['id']),
        TextCellValue(order['userId'] ?? ''),
        IntCellValue(order['totalHarga']),
        TextCellValue(order['status'] ?? ''),
        TextCellValue(order['metodePembayaran'] ?? ''),
        TextCellValue(order['createdAt'] ?? ''),
      ]);
    }

    // Simpan file di Documents app directory
    final directory = await getApplicationDocumentsDirectory();

    String fileName = 'laporan_penjualan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    String filePath = '${directory.path}/$fileName';

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      _showMessage('Gagal membuat file Excel');
      return;
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes, flush: true);

    _showMessage('Berhasil menyimpan file:\n$filePath');

    OpenFile.open(filePath);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void resetFilter() {
    setState(() {
      filterDate = null;
      filterMonth = null;
      filterYear = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'tanggal':
                  pickFilterDate();
                  break;
                case 'bulan':
                  pickFilterMonth();
                  break;
                case 'tahun':
                  pickFilterYear();
                  break;
                case 'reset':
                  resetFilter();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'tanggal', child: Text('Filter Tanggal')),
              PopupMenuItem(value: 'bulan', child: Text('Filter Bulan')),
              PopupMenuItem(value: 'tahun', child: Text('Filter Tahun')),
              PopupMenuItem(value: 'reset', child: Text('Reset Filter')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Export Excel',
            onPressed: exportToExcel,
          ),
        ],
      ),
      drawer: DrawerAdmin(
        onSelectMenu: (menu) {
          Navigator.pop(context);
        },
        scaffoldContext: context,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredOrders.isEmpty
          ? const Center(
        child: Text(
          'Tidak ada data pesanan',
          style: TextStyle(color: Colors.black54),
        ),
      )
          : ListView.builder(
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          final createdAt =
          DateTime.parse(order['createdAt'].toString());
          return Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order['id']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0D47A1))),
                  const SizedBox(height: 4),
                  Text('User ID: ${order['userId']}'),
                  Text('Total Harga: Rp${order['totalHarga']}'),
                  Text('Status: ${order['status']}'),
                  Text('Metode Pembayaran: ${order['metodePembayaran']}'),
                  Text(
                    'Tanggal: ${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
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
