import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:kopinang/widgets/drawer_admin.dart';


class LacakOrderPage extends StatefulWidget {
  const LacakOrderPage({Key? key}) : super(key: key);

  @override
  State<LacakOrderPage> createState() => _LacakOrderPageState();
}


class _LacakOrderPageState extends State<LacakOrderPage> {
  final TextEditingController _orderIdController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  double? orderLat;
  double? orderLng;

  double? adminLat;
  double? adminLng;

  late final MapController _mapController;

  StreamSubscription<Position>? _positionStreamSubscription;

  final String baseUrl = 'http://192.168.1.7/api/order';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startListeningLocation();
  }

  void _startListeningLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Layanan lokasi tidak aktif. Mohon aktifkan GPS.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = 'Izin lokasi ditolak.';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
      });
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update tiap 10 meter
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        adminLat = position.latitude;
        adminLng = position.longitude;
      });

      // Gerakkan map ke posisi admin baru (zoom 15)
      _mapController.move(LatLng(adminLat!, adminLng!), 15);
    });
  }

  Future<void> fetchOrderLocation(int orderId) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      orderLat = null;
      orderLng = null;
    });

    try {
      final url = Uri.parse('$baseUrl/$orderId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['latitude'] != null && data['longitude'] != null) {
          setState(() {
            orderLat = (data['latitude'] as num).toDouble();
            orderLng = (data['longitude'] as num).toDouble();
          });
        } else {
          setState(() {
            errorMessage = 'Lokasi pesanan tidak tersedia.';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Pesanan tidak ditemukan.';
        });
      } else {
        setState(() {
          errorMessage = 'Terjadi kesalahan saat mengambil data.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal menghubungi server: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String calculateDistance() {
    if (orderLat == null || orderLng == null || adminLat == null || adminLng == null) return '';

    final Distance distance = Distance();
    final double meters = distance.as(
      LengthUnit.Meter,
      LatLng(adminLat!, adminLng!),
      LatLng(orderLat!, orderLng!),
    );

    if (meters >= 1000) {
      return 'Jarak: ${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return 'Jarak: ${meters.toStringAsFixed(0)} m';
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? orderPosition = (orderLat != null && orderLng != null) ? LatLng(orderLat!, orderLng!) : null;
    final LatLng? adminPosition = (adminLat != null && adminLng != null) ? LatLng(adminLat!, adminLng!) : null;

    // Center map di tengah antara admin dan order jika ada, atau admin, atau titik default
    LatLng centerMap = const LatLng(-7.7829, 113.9094);
    if (adminPosition != null && orderPosition != null) {
      centerMap = LatLng(
        (adminLat! + orderLat!) / 2,
        (adminLng! + orderLng!) / 2,
      );
    } else if (adminPosition != null) {
      centerMap = adminPosition;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Pesanan (Admin)'),
      ),
      drawer: DrawerAdmin(
        onSelectMenu: (menu) {
          Navigator.pop(context);
        },
        scaffoldContext: context,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Masukkan Order ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                final id = int.tryParse(value);
                if (id != null) {
                  fetchOrderLocation(id);
                } else {
                  setState(() {
                    errorMessage = 'ID harus berupa angka valid.';
                    orderLat = null;
                    orderLng = null;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                final id = int.tryParse(_orderIdController.text);
                if (id != null) {
                  fetchOrderLocation(id);
                } else {
                  setState(() {
                    errorMessage = 'ID harus berupa angka valid.';
                    orderLat = null;
                    orderLng = null;
                  });
                }
              },
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Lacak Pesanan'),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (orderPosition != null && adminPosition != null)
              Text(
                calculateDistance(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            if (adminPosition != null)
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerMap,
                    initialZoom: 13,
                  ),

                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.kopinang',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: adminPosition,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        if (orderPosition != null)
                          Marker(
                            point: orderPosition,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                    if (orderPosition != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [adminPosition, orderPosition],
                            strokeWidth: 4,
                            color: Colors.green,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
