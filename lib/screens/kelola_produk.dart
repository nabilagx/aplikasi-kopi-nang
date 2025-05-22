import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kopinang/widgets/drawer_admin.dart';


class KelolaProdukPage extends StatefulWidget {
  @override
  _KelolaProdukPageState createState() => _KelolaProdukPageState();
}

class _KelolaProdukPageState extends State<KelolaProdukPage> {
  final picker = ImagePicker();

  DocumentSnapshot? editingProduct;

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();

  File? _imageFile;
  bool _loading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Future<String?> uploadImageToImgur(File image) async {
    try {
      final bytes = await image.readAsBytes();
      String base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgur.com/3/image'), //POST API
        headers: {
          'Authorization': 'Client-ID a48dbd4c499304d',
        },
        body: {
          'image': base64Image,
          'type': 'base64',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success']) {
        return data['data']['link'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void openForm({DocumentSnapshot? product}) {
    if (product != null) {
      _namaController.text = product['nama'] ?? '';
      _deskripsiController.text = product['deskripsi'] ?? '';
      _hargaController.text = product['harga'].toString();
      _stokController.text = product['stok'].toString();
      _imageFile = null;
      editingProduct = product;
    } else {
      _namaController.clear();
      _deskripsiController.clear();
      _hargaController.clear();
      _stokController.clear();
      _imageFile = null;
      editingProduct = null;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future pickImageDialog(ImageSource src) async {
            try {
              final pickedFile = await picker.pickImage(source: src, maxWidth: 800);
              if (pickedFile != null) {
                setStateDialog(() {
                  _imageFile = File(pickedFile.path);
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal ambil gambar: $e')),
              );
            }
          }

          return AlertDialog(
            title: Text(editingProduct == null ? 'Tambah Produk' : 'Edit Produk'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(labelText: 'Nama Produk'),
                      validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: InputDecoration(labelText: 'Deskripsi Produk'),
                      maxLines: 2,
                      validator: (val) => val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _hargaController,
                      decoration: InputDecoration(labelText: 'Harga Produk'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Harga wajib diisi';
                        if (int.tryParse(val) == null) return 'Harga harus angka';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _stokController,
                      decoration: InputDecoration(labelText: 'Stok Produk'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Stok wajib diisi';
                        if (int.tryParse(val) == null) return 'Stok harus angka';
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    _imageFile != null
                        ? Image.file(_imageFile!, height: 150)
                        : (editingProduct != null && editingProduct!['gambar'] != null && editingProduct!['gambar'] != '')
                        ? Image.network(editingProduct!['gambar'], height: 150)
                        : Text('Belum ada gambar'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.photo),
                          label: Text('Galeri'),
                          onPressed: () async {
                            await pickImageDialog(ImageSource.gallery);
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.camera_alt),
                          label: Text('Kamera'),
                          onPressed: () async {
                            await pickImageDialog(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() {
                    _loading = true;
                  });

                  String? imageUrl;
                  if (_imageFile != null) {
                    imageUrl = await uploadImageToImgur(_imageFile!);
                    if (imageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Gagal upload gambar'),
                      ));
                      setState(() {
                        _loading = false;
                      });
                      return;
                    }
                  }

                  try {
                    if (editingProduct == null) {
                      await FirebaseFirestore.instance.collection('produk').add({
                        'nama': _namaController.text.trim(),
                        'deskripsi': _deskripsiController.text.trim(),
                        'harga': int.parse(_hargaController.text.trim()),
                        'stok': int.parse(_stokController.text.trim()),
                        'gambar': imageUrl ?? '',
                        'created_at': FieldValue.serverTimestamp(),
                      });
                    } else {
                      Map<String, dynamic> updateData = {
                        'nama': _namaController.text.trim(),
                        'deskripsi': _deskripsiController.text.trim(),
                        'harga': int.parse(_hargaController.text.trim()),
                        'stok': int.parse(_stokController.text.trim()),
                      };
                      if (imageUrl != null) updateData['gambar'] = imageUrl;

                      await FirebaseFirestore.instance
                          .collection('produk')
                          .doc(editingProduct!.id)
                          .update(updateData);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Produk berhasil disimpan')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal simpan produk: $e')),
                    );
                  } finally {
                    setState(() {
                      _loading = false;
                      _imageFile = null;
                      editingProduct = null;
                    });
                  }
                },
                child: _loading ? CircularProgressIndicator(color: Colors.white) : Text(editingProduct == null ? 'Tambah' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future deleteProduct(String id) async {
    try {
      await FirebaseFirestore.instance.collection('produk').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus produk: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerAdmin(
        scaffoldContext: context,
      ),
      appBar: AppBar(
        title: Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              openForm();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produk').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final produkDocs = snapshot.data!.docs;

          if (produkDocs.isEmpty) {
            return Center(child: Text('Belum ada produk'));
          }

          return ListView.builder(
            itemCount: produkDocs.length,
            itemBuilder: (context, index) {
              final doc = produkDocs[index];
              final data = doc.data()! as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: (data['gambar'] != null && data['gambar'] != '')
                      ? Image.network(data['gambar'], width: 60, fit: BoxFit.cover)
                      : SizedBox(width: 60, child: Icon(Icons.image)),
                  title: Text(data['nama'] ?? '-'),
                  subtitle: Text('Harga: Rp${data['harga']?.toString() ?? '0'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          openForm(product: doc);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteProduct(doc.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
