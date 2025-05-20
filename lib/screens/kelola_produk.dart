import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class KelolaProduk extends StatefulWidget {
  @override
  _KelolaProdukState createState() => _KelolaProdukState();
}

class _KelolaProdukState extends State<KelolaProduk> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.6:3000/upload'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return respStr; // URL gambar dari backend
    } else {
      print('Upload gagal: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _saveProduk() async {
    String nama = _namaController.text.trim();
    String harga = _hargaController.text.trim();

    if (nama.isEmpty || harga.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama, harga dan gambar harus diisi')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl = await uploadImage(_imageFile!);

    if (imageUrl != null) {
      await FirebaseFirestore.instance.collection('produk').add({
        'nama_produk': nama,
        'harga': harga,
        'gambar_url': imageUrl,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil disimpan!')));

      _namaController.clear();
      _hargaController.clear();
      setState(() {
        _imageFile = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload gambar')));
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: _hargaController,
              decoration: InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            _imageFile == null
                ? Text('Belum ada gambar dipilih')
                : Image.file(_imageFile!, height: 150),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pilih Gambar'),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveProduk,
              child: Text('Simpan Produk'),
            )
          ],
        ),
      ),
    );
  }
}
