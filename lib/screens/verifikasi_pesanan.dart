import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:kopinang/widgets/drawer_admin.dart';

class VerifikasiPesananPage extends StatefulWidget {
  const VerifikasiPesananPage({Key? key}) : super(key: key);

  @override
  State<VerifikasiPesananPage> createState() => _VerifikasiPesananPageState();
}

class _VerifikasiPesananPageState extends State<VerifikasiPesananPage> {
  final MobileScannerController scannerController = MobileScannerController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      var result = await Permission.camera.request();
      if (!result.isGranted) {
        _showSnackBar('Izin kamera diperlukan untuk scan QR Code');
        openAppSettings();
      }
    }
  }

  Future<void> verifikasiOrder(String orderId) async {
    try {
      final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Order/$orderId/verifikasi');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _showSnackBar('Pesanan $orderId berhasil diverifikasi dan selesai.');
      } else {
        String message = 'Gagal verifikasi: ${response.statusCode}';

        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map && responseData.containsKey('message')) {
            final serverMessage = responseData['message'] as String;
            if (serverMessage.toLowerCase().contains('selesai')) {
              message = 'Pesanan ini sudah pernah diverifikasi sebelumnya.';
            } else {
              message = serverMessage;
            }
          }
        } catch (_) {
          // kalau gagal decode, tetap pakai message default
        }

        _showSnackBar(message);
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }



  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final orderId = barcodes.first.rawValue;
    if (orderId == null) return;

    setState(() {
      isProcessing = true;
    });

    await verifikasiOrder(orderId);

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isProcessing = false;
    });
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pesanan'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      drawer: DrawerAdmin(
        onSelectMenu: (menu) {
          Navigator.pop(context);
        },
        scaffoldContext: context,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: _handleBarcode,
          ),
          if (!isProcessing)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF0D47A1), width: 4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (!isProcessing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF0D47A1).withOpacity(0.9),
                child: const Text(
                  'Arahkan kamera ke QR Code pesanan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),

    );
  }
}
