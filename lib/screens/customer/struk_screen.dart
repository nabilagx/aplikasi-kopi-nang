import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';

class StrukScreen extends StatefulWidget {
  final String orderId;
  final String metodePembayaran;
  final int totalHarga;
  final List<Map<String, dynamic>> items;
  final String? qrCodeUrl;

  const StrukScreen({
    super.key,
    required this.orderId,
    required this.metodePembayaran,
    required this.totalHarga,
    required this.items,
    this.qrCodeUrl,
  });

  @override
  State<StrukScreen> createState() => _StrukScreenState();
}

class _StrukScreenState extends State<StrukScreen> {
  final GlobalKey _globalKey = GlobalKey();
  static const primaryColor = Color(0xFF0D47A1);
  final formatter = NumberFormat.decimalPattern('id');

  Future<void> _simpanStruk() async {
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/struk_${widget.orderId}.png');
      await file.writeAsBytes(pngBytes);

      showKopiNangAlert(context, "Tersimpan", "Struk berhasil disimpan", type: 'success');
    } catch (e) {
      showKopiNangAlert(context, "Gagal", "Gagal menyimpan struk: $e", type: 'error');
    }
  }

  Future<void> _bagikanStruk() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/struk_${widget.orderId}.png';
    final file = File(path);

    if (await file.exists()) {
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Struk KOPI NANG');
    } else {
      showKopiNangAlert(context, "Peringatan", "Struk belum disimpan", type: 'warning');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSebelumDiskon = widget.items.fold<int>(0, (sum, item) {
      return sum + ((item['harga'] as num) * (item['qty'] as num)).toInt();
    });
    final diskon = totalSebelumDiskon - widget.totalHarga;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Struk Pesanan"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RepaintBoundary(
              key: _globalKey,
              child: ClipPath(
                clipper: TicketClipper(),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', height: 60),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order ID: ${widget.orderId}'),
                            Text('Metode: ${widget.metodePembayaran}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Detail Pesanan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            final harga = item['harga'] as int;
                            final qty = item['qty'] as int;
                            final subtotal = harga * qty;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(flex: 4, child: Text(item['nama'] ?? 'Produk')),
                                    Expanded(
                                      flex: 2,
                                      child: Center(child: Text('x$qty')),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('Rp${formatter.format(subtotal)}'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '  @ Rp${formatter.format(harga)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            );
                          }

                      ),
                      const Divider(height: 32, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('Rp${formatter.format(totalSebelumDiskon)}'),
                        ],
                      ),
                      if (diskon > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diskon'),
                            Text('- Rp${formatter.format(diskon)}'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Divider(height: 24, thickness: 1),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Harga',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'Rp${formatter.format(widget.totalHarga)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.qrCodeUrl != null) ...[
                        const Text(
                          'Tunjukkan QR ini ke kasir',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: widget.qrCodeUrl!,
                          size: 160,
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _simpanStruk,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text("Simpan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _bagikanStruk,
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text("Bagikan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text("Kembali ke Beranda"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 20.0;
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(0, size.height / 2 - radius);
    path.arcToPoint(
      Offset(0, size.height / 2 + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height / 2 + radius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
