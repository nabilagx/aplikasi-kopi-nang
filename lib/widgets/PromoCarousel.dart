import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCarousel extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> promos;

  const PromoCarousel({super.key, required this.promos});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _controller;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.hasClients && widget.promos.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % widget.promos.length;
        _controller.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter hanya promo aktif
    final activePromos = widget.promos.where((doc) {
      final data = doc.data();
      return data['aktif'] == true;
    }).toList();

    if (activePromos.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No promos available')),
      );
    }

    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: activePromos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final promo = activePromos[index].data();

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Image.network(
                      promo['gambar'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 50,
                                color: Colors.grey),
                          ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.black.withOpacity(0.6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            promo['judul'] ?? 'No Title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gunakan kode: ${promo['kode'] ?? '-'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Indicator dots
          Positioned(
            bottom: 8,
            right: 12,
            child: Row(
              children: List.generate(activePromos.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 12 : 8,
                  height: _currentIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.white : Colors
                        .white54,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

}
