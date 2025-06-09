import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';


class StrukScreen extends StatelessWidget {
  final String orderId;
  final String metodePembayaran;
  final int totalHarga;
  final List<Map<String, dynamic>> items;
  final String? qrCodeUrl; // Tambahan parameter opsional

  const StrukScreen({
    super.key,
    required this.orderId,
    required this.metodePembayaran,
    required this.totalHarga,
    required this.items,
    this.qrCodeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: $orderId'),
            Text('Metode Pembayaran: $metodePembayaran'),
            Text('Total Harga: Rp$totalHarga'),
            const SizedBox(height: 16),
            const Text('Detail Pesanan:'),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item['nama'] ?? 'Produk'),
                    subtitle: Text('Jumlah: ${item['qty']}'),
                    trailing: Text('Rp${item['harga'] * item['qty']}'),
                  );
                },
              ),
            ),

            if (qrCodeUrl != null) ...[
              const SizedBox(height: 16),
              const Text('QR Code:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: Image.network(qrCodeUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
