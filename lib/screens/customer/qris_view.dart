import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'struk_screen.dart';

class QrisWebViewPage extends StatefulWidget {
  final String url;
  final String orderId;

  const QrisWebViewPage({required this.url, required this.orderId, super.key});

  @override
  State<QrisWebViewPage> createState() => _QrisWebViewPageState();
}

class _QrisWebViewPageState extends State<QrisWebViewPage> {
  bool isNavigatedToStruk = false;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _startPollingStatus();
    _webViewController = WebViewController()
      ..loadRequest(Uri.parse(widget.url))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  void _startPollingStatus() async {
    while (mounted && !isNavigatedToStruk) {
      await Future.delayed(const Duration(seconds: 5));
      await _checkPaymentStatus();
    }
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final response = await http.post(
        Uri.parse('https://kopinang-api-production.up.railway.app/api/order/${widget.orderId}/verifikasi-midtrans'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['transaction_status'];

        if (status == 'settlement' && !isNavigatedToStruk) {
          setState(() {
            isNavigatedToStruk = true;
          });

          await _navigateToStruk();
        }
      }
    } catch (e) {
      print("Error checking payment status: $e");
    }
  }

  Future<void> _navigateToStruk() async {
    final orderRes = await http.get(
      Uri.parse('https://kopinang-api-production.up.railway.app/api/order/${widget.orderId}'),
    );

    if (orderRes.statusCode == 200) {
      final orderData = jsonDecode(orderRes.body);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StrukScreen(
            orderId: widget.orderId,
            metodePembayaran: 'QRIS',
            totalHarga: orderData['totalHarga'],
            items: List<Map<String, dynamic>>.from(orderData['orderDetails'] ?? []),
            qrCodeUrl: orderData['qrCode'] ?? '',
          ),
        ),
      );
    }
  }

  Future<void> _manualCheckStatus() async {
    final response = await http.post(
      Uri.parse('https://kopinang-api-production.up.railway.app/api/order/${widget.orderId}/verifikasi-midtrans'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final status = data['transaction_status'];

      if (status == 'settlement') {
        setState(() {
          isNavigatedToStruk = true;
        });
        await _navigateToStruk();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status masih belum dibayar atau pending.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal cek status pembayaran.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        title: const Text(
          "KOPI NANG - Pembayaran QRIS",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Scan QRIS Berikut untuk Melanjutkan Pembayaran",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: WebViewWidget(
                  controller: _webViewController,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Tunggu hingga pembayaran selesai...",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed: _manualCheckStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Saya Sudah Bayar", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
