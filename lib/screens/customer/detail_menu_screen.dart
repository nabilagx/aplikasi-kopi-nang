import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class DetailMenuScreen extends StatelessWidget {
  final Map<String, dynamic> menuData;

  const DetailMenuScreen({super.key, required this.menuData});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(menuData['nama'] ?? 'Detail Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                menuData['gambar'] ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              menuData['nama'] ?? 'Tanpa Nama',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${menuData['harga']?.toString() ?? '0'}',
              style: const TextStyle(fontSize: 20, color: Colors.brown),
            ),
            const SizedBox(height: 16),
            Text(
              menuData['deskripsi'] ?? 'Tidak ada deskripsi.',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).addItem(menuData);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
                  );
                },
                child: const Text("Tambah ke Keranjang"),
              ),
            ),
          ],

        ),
      ),
    );
  }
}
