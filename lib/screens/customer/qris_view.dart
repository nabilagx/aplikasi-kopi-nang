import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'struk_screen.dart';

class QrisWebViewPage extends StatefulWidget {
  final String url;
  final String orderId;

  const QrisWebViewPage({required this.url, required this.orderId});

  @override
  State<QrisWebViewPage> createState() => _QrisWebViewPageState();
}

class _QrisWebViewPageState extends State<QrisWebViewPage> {
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Optionally: polling status pembayaran setiap 5 detik
    Future.delayed(Duration(seconds: 20), checkStatusPembayaran);
  }

  Future<void> checkStatusPembayaran() async {
    final response = await http.get(
        Uri.parse('http://192.168.1.7/api/order/${widget.orderId}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final status = data['status'];
      if (status == 'Selesai' || status == 'Dibayar') {
        if (!isCompleted) {
          setState(() => isCompleted = true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StrukScreen(
                    orderId: widget.orderId,
                    metodePembayaran: 'QRIS',
                    totalHarga: data['totalHarga'],
                    items: List<Map<String, dynamic>>.from(
                        data['orderDetails']),
                    qrCodeUrl: data['qrCode'],
                  ),
            ),
          );
        }
      } else {
        Future.delayed(
            Duration(seconds: 20), checkStatusPembayaran); // polling lagi
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KOPI NANG - Pembayaran QRIS"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(
              controller: WebViewController()
                ..loadRequest(Uri.parse(widget.url))
                ..setJavaScriptMode(JavaScriptMode.unrestricted),
            ),
          ),
        ],
      ),
    );
  }
}
