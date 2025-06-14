import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'qris_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  //final List<String> _ewalletOptions = ['Dana', 'OVO', 'GoPay', 'ShopeePay'];

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Promo berhasil! Diskon Rp$_discount diterapkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode promo tidak valid: $e')),
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

    final response = await http.post(
      Uri.parse('https://kopinang-api-production.up.railway.app/api/order/payment/qris'),
      headers: {"Content-Type": "application/json"},
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
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

      // 1. Buat order dulu tanpa QR code
      final response = await http.post(
        Uri.parse('https://kopinang-api-production.up.railway.app/api/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderId = data['id'].toString();

        if (_selectedPaymentMethod == 'QRIS') {
          await createMidtransTransaction(
            orderId: int.parse(orderId),
            totalHarga: totalHarga.toInt(),
            nama: user.displayName ?? 'User',
            email: user.email ?? 'user@example.com',
          );
        }

        // 2. Generate & upload QR ke Imgur dari orderId
        final qrUrl = await generateAndUploadQr(orderId);

        // 3. Update order dengan QR code URL (PATCH/PUT)
        final updatePayload = {"qrCode": qrUrl, "updatedAt": DateTime.now().toUtc().toIso8601String()};

        final updateResponse = await http.put(
          Uri.parse('https://kopinang-api-production.up.railway.app/api/order/$orderId/qrcode'),
          headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"qrCode": qrUrl}),
          // Tanpa properti, langsung string
        );

        print('Mengirim QR code ke backend: $qrUrl');
        print('Status code: ${updateResponse.statusCode}');
        print('Body: ${updateResponse.body}');




        if (updateResponse.statusCode != 200) {
          throw Exception('Gagal update QR code ke backend');
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
              qrCodeUrl: qrUrl,  // Kalau mau tampilkan QR di struk


            ),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Gagal membuat pesanan: ${error.toString()}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat checkout: $e')),
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
      appBar: AppBar(title: const Text("Keranjang")),
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
                return ListTile(
                  leading: Image.network(
                    item['gambar'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item['nama']),
                  subtitle: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cart.decreaseQty(index),
                      ),
                      Text('${item['qty']}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => cart.increaseQty(index),
                      ),
                    ],
                  ),
                  trailing: Text('Rp${_currencyFormat.format(item['harga'] * item['qty'])}'),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _promoController,
                decoration: InputDecoration(
                  labelText: 'Kode Promo',
                  suffixIcon: _isCheckingPromo
                      ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                      : IconButton(
                    icon: const Icon(Icons.check),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Metode Pembayaran',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPaymentMethod,
                items: _paymentMethods
                    .map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;

                  });
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total: Rp${_currencyFormat.format(displayTotal)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: _isCheckoutLoading ? null : () => _onCheckout(cart),
              child: _isCheckoutLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
