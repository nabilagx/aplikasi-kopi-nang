import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';

import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/PromoCarousel.dart';
import 'detail_menu_screen.dart';
import 'cart_screen.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';


class HomeCustomer extends StatefulWidget {
  const HomeCustomer({super.key});

  @override
  State<HomeCustomer> createState() => _HomeCustomerState();
}

class _HomeCustomerState extends State<HomeCustomer> {
  String searchQuery = '';
  String locationText = 'Mencari lokasi...';
  final String apiBaseUrl = 'https://kopinang-api-production.up.railway.app/api/Produk';

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartLocation();
  }

  Future<void> _checkPermissionAndStartLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationText = 'Lokasi perangkat tidak aktif';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationText = 'Izin lokasi ditolak';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationText = 'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
      });
      return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateAddressFromPosition(position);
    });
  }


  Future<void> _updateAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          locationText = '${place.subLocality ?? ''}, ${place.locality ?? ''}'.trim();
          if (locationText == ',') locationText = 'Lokasi tidak tersedia';
        });
      } else {
        setState(() {
          locationText =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        locationText = 'Gagal mendapatkan alamat';
      });
    }
  }

  Future<List<dynamic>> fetchProduk() async {
    final response = await http.get(Uri.parse(apiBaseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.where((item) {
        final nama = item['nama']?.toString().toLowerCase() ?? '';
        return nama.contains(searchQuery);
      }).toList();
    } else {
      throw Exception('Gagal mengambil produk');
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header lokasi dan ikon chat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Location', style: TextStyle(color: Colors.grey)),
                    Text(
                      locationText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [

                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Search bar
            TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari kopi...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Promo dari Firebase Firestore
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('promos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final promos = snapshot.data?.docs ?? [];
                return PromoCarousel(promos: promos);
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Semua Produk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Produk dari API
            FutureBuilder<List<dynamic>>(
              future: fetchProduk(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final produk = snapshot.data ?? [];

                if (produk.isEmpty) {
                  return const Center(child: Text('Produk tidak ditemukan'));
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: produk.length,
                  itemBuilder: (context, index) {
                    final item = produk[index];
                    final bool isOutOfStock = item['stok'] == 0;

                    return GestureDetector(
                      onTap: isOutOfStock
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailMenuScreen(menuData: item),
                          ),
                        );
                      },
                      child: Opacity(
                        opacity: isOutOfStock ? 0.6 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gambar produk
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          item['gambar'] ?? '',
                                          height: 90,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                          ),
                                        ),
                                        if (isOutOfStock)
                                          Container(
                                            height: 120,
                                            width: double.infinity,
                                            color: Colors.black.withOpacity(0.5),
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'SOLD',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Info Produk
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['nama'] ?? '-',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rp${item['harga'] ?? '-'}',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['deskripsi'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Spacer(),

                                  if (!isOutOfStock)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 28),
                                        onPressed: () {
                                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                          cartProvider.addItem({
                                            'id': item['id'],
                                            'nama': item['nama'],
                                            'harga': item['harga'],
                                            'gambar': item['gambar'],
                                            'jumlah': 1,
                                          });

                                          showKopiNangAlert(context, 'Berhasil!', '${item['nama']} telah ditambahkan ke keranjang.');

                                        },
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
