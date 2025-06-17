import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'qris_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


import 'cart_provider.dart';
import 'struk_screen.dart';



class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();
  int _discount = 0;
  bool _isCheckingPromo = false;
  bool _isCheckoutLoading = false;

  String? _selectedPaymentMethod;


  final List<String> _paymentMethods = ['Bayar di Tempat', 'QRIS'];

  final NumberFormat _currencyFormat = NumberFormat("#,##0", "id_ID");

  Future<void> _checkPromoCode(String code, num totalBelanja) async {
    setState(() {
      _isCheckingPromo = true;
      _discount = 0;
    });

    try {
      final promoQuery = await FirebaseFirestore.instance
          .collection('promos')
          .where('kode', isEqualTo: code)
          .where('aktif', isEqualTo: true)
          .limit(1)
          .get();

      if (promoQuery.docs.isEmpty) {
        throw Exception("Kode promo tidak ditemukan atau tidak aktif");
      }

      final promoDoc = promoQuery.docs.first;
      final data = promoDoc.data();
      final kuota = data['kuota'] ?? 0;
      final minBelanja = data['minimal_belanja'] ?? 0;
      final potongan = data['potongan'] ?? 0;

      if (kuota <= 0) {
        throw Exception("Promo sudah habis kuotanya");
      }

      if (totalBelanja < minBelanja) {
        throw Exception("Belanja belum mencapai minimal Rp${minBelanja}");
      }

      // Semua valid → pakai promo
      await promoDoc.reference.update({'kuota': kuota - 1});

      setState(() {
        _discount = potongan;
      });

      showKopiNangAlert(
        context,
        "Promo Berhasil",
        "Diskon Rp$_discount diterapkan.",
        type: 'success',
      );

    } catch (e) {
      showKopiNangAlert(
        context,
        "Kode Promo Tidak Valid",
        "Terjadi kesalahan: $e",
        type: 'error',
      );

    } finally {
      setState(() {
        _isCheckingPromo = false;
      });
    }
  }


  Future<void> createMidtransTransaction({
    required int orderId,
    required int totalHarga,
    required String nama,
    required String email,
  }) async {
    final body = {
      "uid": FirebaseAuth.instance.currentUser!.uid,
      "orderId": orderId,
      "totalHarga": totalHarga,
      "nama": nama,
      "email": email,
    };

    print("GROSS AMOUNT: $totalHarga (${totalHarga.runtimeType})");


    if (totalHarga <= 0) {
      print("Error: Total harga tidak valid: $totalHarga");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('Pengguna belum login');
    }

    if (idToken == null) {
      throw Exception('User belum login atau token tidak tersedia');
    }

    final response = await http.post(
      Uri.parse('https://kopinang-api-production.up.railway.app/api/order/payment/qris'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode(body),
    );



    print('Response: ${response.statusCode} => ${response.body}');

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY:\n${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final snapUrl = data['actions'][0]['url']; // ✅ ambil dari actions
      final orderId = data['order_id']; // ✅ sudah tersedia di response

      if (snapUrl != null && orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QrisWebViewPage(
              url: snapUrl,
              orderId: orderId,
            ),
          ),
        );
      } else {
        throw Exception('URL atau Order ID tidak tersedia');
      }
    } else {
      throw Exception('Gagal membuat transaksi Midtrans: ${response.body}');
    }
  }


// Fungsi generate dan upload QR ke Imgur
  Future<String> generateAndUploadQr(String orderId) async {
    final qrValidationResult = QrValidator.validate(
      data: orderId,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    final picData = await painter.toImageData(300, format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = picData!.buffer.asUint8List();

    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {
        'Authorization': 'Client-ID a48dbd4c499304d', // Ganti dengan client-id Imgur kamu
      },
      body: {
        'image': base64Encode(pngBytes),
        'type': 'base64',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['link'];
    } else {
      throw Exception('Upload QR ke Imgur gagal: ${data['data']['error']}');
    }
  }


  Future<void> _onCheckout(CartProvider cart) async {
    if (_selectedPaymentMethod == null) {
      showKopiNangAlert(
        context,
        "Metode Pembayaran",
        "Silakan pilih metode pembayaran terlebih dahulu.",
        type: 'warning',
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong')),
      );
      return;
    }

    setState(() {
      _isCheckoutLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna belum login')),
        );
        setState(() {
          _isCheckoutLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final totalHarga = cart.totalHarga - _discount;

      final List<Map<String, dynamic>> orderDetails = cart.items.map((item) {
        return {
          "produkId": item['id'],
          "jumlah": item['qty'],
          "hargaSatuan": item['harga'],
        };
      }).toList();

      final payload = {
        "userId": user.uid,
        "totalHarga": totalHarga.toInt(),
        "status": "Diproses",
        "metodePembayaran": _selectedPaymentMethod,
        "buktiPembayaran": _selectedPaymentMethod,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "createdAt": DateTime.now().toUtc().toIso8601String(),
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
        "orderDetails": orderDetails,
      };

      final idToken = await user?.getIdToken();

      if (idToken == null) {
        throw Exception('User belum login.');
      }

      final response = await http.post(
        Uri.parse('https://kopinang-api-production.up.railway.app/api/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(payload),
      );


      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderId = data['id'].toString();


        if (_selectedPaymentMethod == 'QRIS') {
          final user = FirebaseAuth.instance.currentUser;

          await createMidtransTransaction(
            orderId: int.parse(orderId),
            totalHarga: totalHarga.toInt(),
            nama: user?.displayName ?? 'User',
            email: user?.email ?? 'user@example.com',
          );

        }

        final qrUrl = await generateAndUploadQr(orderId);
        final updatePayload = {"qrCode": qrUrl, "updatedAt": DateTime.now().toUtc().toIso8601String()};


        final idToken = await user?.getIdToken();

        if (idToken == null) {
          throw Exception('User belum login');
        }

        final updateResponse = await http.put(
          Uri.parse('https://kopinang-api-production.up.railway.app/api/order/$orderId/qrcode'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({"qrCode": qrUrl}),
        );


        print('Mengirim QR code ke backend: $qrUrl');
        print('Status code: ${updateResponse.statusCode}');
        print('Body: ${updateResponse.body}');

        if (updateResponse.statusCode != 200) {
          throw Exception('Gagal update QR code ke backend');
        }

        // stok - qty
        for (var item in cart.items) {
          final kurangiStokResponse = await http.put(
            Uri.parse('https://kopinang-api-production.up.railway.app/api/produk/${item['id']}/kurangi-stok'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({"jumlah": item['qty']}),
          );

          if (kurangiStokResponse.statusCode != 200) {
            throw Exception('Gagal mengurangi stok produk ${item['nama']}');
          }
        }

        final itemsCopy = List<Map<String, dynamic>>.from(cart.items);
        cart.clearCart();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StrukScreen(
              orderId: orderId,
              metodePembayaran: _selectedPaymentMethod!,
              totalHarga: totalHarga.toInt(),
              items: itemsCopy,
              qrCodeUrl: qrUrl,


            ),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Gagal membuat pesanan: ${error.toString()}');
      }
    } catch (e) {
      showKopiNangAlert(
        context,
        "Gagal Checkout",
        "Terjadi kesalahan: $e",
        type: 'error',
      );
    } finally {
      setState(() {
        _isCheckoutLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = cart.totalHarga - _discount;
    final displayTotal = total > 0 ? total : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['gambar'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item['nama'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cart.decreaseQty(index),
                        ),
                        Text('${item['qty']}', style: const TextStyle(
                            fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cart.increaseQty(index),
                        ),
                      ],
                    ),
                    trailing: Text(
                      'Rp${_currencyFormat.format(
                          item['harga'] * item['qty'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _promoController,
                decoration: InputDecoration(
                  labelText: 'Kode Promo',
                  labelStyle: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  prefixIcon: Icon(Icons.card_giftcard, color: Colors.blue.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade600, width: 1.8),
                  ),
                  suffixIcon: _isCheckingPromo
                      ? Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: Colors.blue.shade600,
                    ),
                    onPressed: () {
                      final code = _promoController.text.trim();
                      if (code.isNotEmpty) {
                        _checkPromoCode(code, cart.totalHarga);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Metode Pembayaran',
                  prefixIcon: Icon(Icons.payment, color: Colors.blue.shade400),
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
                dropdownColor: Colors.blue.shade50,
                value: _selectedPaymentMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(
                      method,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18)),
                  Text(
                    'Rp${_currencyFormat.format(displayTotal)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCheckoutLoading ? null : () =>
                      _onCheckout(cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCheckoutLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Checkout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
