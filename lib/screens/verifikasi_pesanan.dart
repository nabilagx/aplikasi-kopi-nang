import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:kopinang/widgets/drawer_admin.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        showKopiNangAlert(
          context,
          'Izin Ditolak',
          'Izin kamera diperlukan untuk scan QR Code',
          type: 'warning',
        );
        openAppSettings();
      }
    }
  }

  Future<void> verifikasiOrder(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      if (idToken == null) {
        showKopiNangAlert(
          context,
          'Gagal',
          'Anda belum login.',
          type: 'error',
        );
        return;
      }

      final url = Uri.parse('https://kopinang-api-production.up.railway.app/api/Order/$orderId/verifikasi');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        showKopiNangAlert(
          context,
          'Berhasil',
          'Pesanan $orderId berhasil diverifikasi dan selesai.',
          type: 'success',
        );
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
          // Gunakan fallback message
        }

        showKopiNangAlert(
          context,
          'Gagal',
          message,
          type: 'error',
        );
      }
    } catch (e) {
      showKopiNangAlert(
        context,
        'Kesalahan',
        'Terjadi kesalahan saat verifikasi: $e',
        type: 'error',
      );
    }
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
