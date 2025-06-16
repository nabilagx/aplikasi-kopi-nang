import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:kopinang/widgets/drawer_admin.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KelolaProdukPage extends StatefulWidget {
  @override
  _KelolaProdukPageState createState() => _KelolaProdukPageState();
}

class _KelolaProdukPageState extends State<KelolaProdukPage> {
  final picker = ImagePicker();

  Map<String, dynamic>? editingProduct;

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();

  File? _imageFile;
  bool _loading = false;

  final String apiBaseUrl = 'https://kopinang-api-production.up.railway.app/api/Produk';

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
        Uri.parse('https://api.imgur.com/3/image'),
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

  void openForm({Map<String, dynamic>? product}) {
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
              showKopiNangAlert(
                context,
                "Gagal",
                "Gagal ambil gambar: $e",
                type: 'error',
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
                          icon: Icon(
                            Icons.photo,
                            color: Color(0xFF0D47A1),
                          ),
                          label: Text('Galeri', style: TextStyle(color: Color(0xFF0D47A1))),
                          onPressed: () async {
                            await pickImageDialog(ImageSource.gallery);
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(
                            Icons.camera_alt,
                            color: Color(0xFF0D47A1),
                          ),
                          label: Text('Kamera', style: TextStyle(color: Color(0xFF0D47A1))),
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
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF0D47A1),
                ),
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
                      showKopiNangAlert(
                        context,
                        "Gagal Upload",
                        "Gagal upload gambar",
                        type: 'error',
                      );
                      setState(() {
                        _loading = false;
                      });
                      return;
                    }
                  }

                  try {
                    Map<String, dynamic> productData;

                    if (editingProduct == null) {
                      // TAMBAH PRODUK (POST) — tanpa id dan createdAt
                      productData = {
                        'nama': _namaController.text.trim(),
                        'deskripsi': _deskripsiController.text.trim(),
                        'harga': int.parse(_hargaController.text.trim()),
                        'stok': int.parse(_stokController.text.trim()),
                        'gambar': imageUrl ?? '',
                        'updatedAt': DateTime.now().toIso8601String(),
                      };

                      final response = await http.post(
                        Uri.parse(apiBaseUrl),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(productData),
                      );

                      if (response.statusCode != 201) {
                        print('Error response: ${response.body}');
                        throw Exception('Gagal tambah produk');
                      }
                    } else {
                      // EDIT PRODUK (PUT) — dengan id dan createdAt
                      productData = {
                        'id': editingProduct!['id'],
                        'nama': _namaController.text.trim(),
                        'deskripsi': _deskripsiController.text.trim(),
                        'harga': int.parse(_hargaController.text.trim()),
                        'stok': int.parse(_stokController.text.trim()),
                        'gambar': imageUrl ?? editingProduct!['gambar'],
                        'createdAt': editingProduct!['createdAt'],
                        'updatedAt': DateTime.now().toIso8601String(),
                      };

                      final id = editingProduct!['id'].toString();
                      final response = await http.put(
                        Uri.parse('$apiBaseUrl/$id'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(productData),
                      );

                      if (response.statusCode != 200) {
                        print('Error response: ${response.body}');
                        throw Exception('Gagal update produk');
                      }
                    }

                    Navigator.pop(context);
                    showKopiNangAlert(
                      context,
                      "Produk Disimpan",
                      "Produk berhasil disimpan",
                      type: 'success',
                    );
                    setState(() {
                      _imageFile = null;
                      editingProduct = null;
                    });
                  } catch (e) {
                    showKopiNangAlert(
                      context,
                      "Gagal",
                      "Gagal simpan produk: $e",
                      type: 'error',
                    );
                  } finally {
                    setState(() {
                      _loading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(editingProduct == null ? 'Tambah' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('$apiBaseUrl/$id'));
      if (response.statusCode == 200) {
        showKopiNangAlert(
          context,
          "Produk Dihapus",
          "Produk berhasil dihapus",
          type: 'success',
        );
      } else {
        throw Exception('Gagal hapus produk');
      }
    } catch (e) {
      showKopiNangAlert(
        context,
        "Produk Dihapus",
        "Gagal hapus produk: $e",
        type: 'error',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('User belum login atau token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse(apiBaseUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Gagal mengambil produk: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      drawer: DrawerAdmin(scaffoldContext: context),
      appBar: AppBar(
        title: Text('Kelola Produk'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              openForm();
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final products = snapshot.data!;
          if (products.isEmpty) return Center(child: Text('Belum ada produk'));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // refresh UI dengan FutureBuilder
            },
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, index) {
                final p = products[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: (p['gambar'] != null && p['gambar'] != '')
                        ? Image.network(p['gambar'], width: 60, fit: BoxFit.cover)
                        : Container(width: 60, color: Colors.grey[300], child: Icon(Icons.image_not_supported)),
                    title: Text(p['nama'] ?? ''),
                    subtitle: Text('Harga: Rp${p['harga'] ?? 0} | Stok: ${p['stok'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Color(0xFF0D47A1)),
                          onPressed: () {
                            openForm(product: p);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Konfirmasi'),
                                content: Text('Hapus produk "${p['nama']}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
                                  ),

                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Hapus'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await deleteProduct(p['id'].toString());
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
