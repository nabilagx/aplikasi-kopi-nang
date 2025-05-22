import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kopinang/widgets/drawer_admin.dart';

class PromoAdminPage extends StatefulWidget {
  @override
  _PromoAdminPageState createState() => _PromoAdminPageState();
}

class _PromoAdminPageState extends State<PromoAdminPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _kuotaController = TextEditingController();
  final TextEditingController _minBelanjaController = TextEditingController();
  final TextEditingController _potonganController = TextEditingController();
  final TextEditingController _potonganMaksController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  String _tipeDiskon = 'persentase';
  bool _isAktif = true; // default aktif


  String? _editingDocId; // Untuk edit mode

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> uploadImageToImgur(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgur.com/3/image'),
        headers: {'Authorization': 'Client-ID a48dbd4c499304d'},
        body: {'image': base64Image, 'type': 'base64'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        return data['data']['link'];
      } else {
        print('Imgur upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload Exception: $e');
      return null;
    }
  }

  Future<void> _submitPromo() async {
    if (_judulController.text.isEmpty ||
        _kodeController.text.isEmpty ||
        _kuotaController.text.isEmpty ||
        _minBelanjaController.text.isEmpty ||
        _potonganController.text.isEmpty ||
        (_tipeDiskon == 'persentase' && _potonganMaksController.text.isEmpty) ||
        (_editingDocId == null && _imageFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Isi semua data dan pilih gambar')),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await uploadImageToImgur(_imageFile!);
      if (imageUrl == null) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload gambar ke Imgur')),
        );
        return;
      }
    }

    final data = {
      'judul': _judulController.text,
      'kode': _kodeController.text,
      'kuota': int.parse(_kuotaController.text),
      'aktif': _isAktif,
      'minimal_belanja': int.parse(_minBelanjaController.text),
      'potongan': int.parse(_potonganController.text),
      'tipe': _tipeDiskon,
    };

    if (_tipeDiskon == 'persentase') {
      data['potongan_maks'] = int.parse(_potonganMaksController.text);
    }

    if (imageUrl != null) {
      data['gambar'] = imageUrl;
    }

    final promosRef = FirebaseFirestore.instance.collection('promos');

    if (_editingDocId == null) {
      // Tambah baru
      await promosRef.add(data);
    } else {
      // Update existing
      await promosRef.doc(_editingDocId).update(data);
    }

    setState(() {
      _isUploading = false;
      _resetForm();
    });

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingDocId == null ? 'Promo berhasil ditambahkan' : 'Promo berhasil diperbarui')),
    );
  }

  void _resetForm() {
    _judulController.clear();
    _kodeController.clear();
    _kuotaController.clear();
    _minBelanjaController.clear();
    _potonganController.clear();
    _potonganMaksController.clear();
    _imageFile = null;
    _tipeDiskon = 'persentase';
    _editingDocId = null;
    _isAktif = true;
  }


  void _showPromoForm({DocumentSnapshot? promoDoc, bool readOnly = false}) {
    if (promoDoc != null) {
      final data = promoDoc.data() as Map<String, dynamic>;
      _judulController.text = data['judul'] ?? '';
      _kodeController.text = data['kode'] ?? '';
      _kuotaController.text = data['kuota'].toString();
      _minBelanjaController.text = data['minimal_belanja'].toString();
      _potonganController.text = data['potongan'].toString();
      _tipeDiskon = data['tipe'] ?? 'persentase';
      _potonganMaksController.text = (data['potongan_maks'] ?? '').toString();
      _imageFile = null; // Reset image for edit, user can pick new image if want
      _editingDocId = promoDoc.id;
      _isAktif = data['aktif'] ?? true;
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      barrierDismissible: !readOnly,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(readOnly ? 'Detail Promo' : (_editingDocId == null ? 'Tambah Promo' : 'Edit Promo')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _judulController,
                  decoration: InputDecoration(labelText: 'Judul Promo'),
                  readOnly: readOnly,
                ),
                TextField(
                  controller: _kodeController,
                  decoration: InputDecoration(labelText: 'Kode Promo'),
                  readOnly: readOnly,
                ),
                TextField(
                  controller: _kuotaController,
                  decoration: InputDecoration(labelText: 'Kuota'),
                  keyboardType: TextInputType.number,
                  readOnly: readOnly,
                ),
                TextField(
                  controller: _minBelanjaController,
                  decoration: InputDecoration(labelText: 'Minimal Belanja'),
                  keyboardType: TextInputType.number,
                  readOnly: readOnly,
                ),
                TextField(
                  controller: _potonganController,
                  decoration: InputDecoration(labelText: 'Potongan'),
                  keyboardType: TextInputType.number,
                  readOnly: readOnly,
                ),
                if (!readOnly) ...[
                  ListTile(
                    title: const Text('Diskon Persentase'),
                    leading: Radio<String>(
                      value: 'persentase',
                      groupValue: _tipeDiskon,
                      onChanged: (value) => setStateDialog(() => _tipeDiskon = value!),
                    ),
                  ),
                  ListTile(
                    title: const Text('Diskon Nominal'),
                    leading: Radio<String>(
                      value: 'nominal',
                      groupValue: _tipeDiskon,
                      onChanged: (value) => setStateDialog(() => _tipeDiskon = value!),
                    ),
                  ),
                  if (_tipeDiskon == 'persentase')
                    TextField(
                      controller: _potonganMaksController,
                      decoration: InputDecoration(labelText: 'Potongan Maks'),
                      keyboardType: TextInputType.number,
                    ),
                  SwitchListTile(
                    title: Text('Promo Aktif'),
                    value: _isAktif,
                    onChanged: readOnly ? null : (val) => setStateDialog(() => _isAktif = val),
                  ),
                  SizedBox(height: 10),
                  _imageFile != null
                      ? Image.file(_imageFile!, height: 150)
                      : promoDoc != null
                      ? Image.network((promoDoc.data() as Map<String, dynamic>)['gambar'], height: 150)
                      : Text('Belum ada gambar'),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setStateDialog(() => _imageFile = File(pickedFile.path));
                      }
                    },
                    icon: Icon(Icons.image),
                    label: Text('Pilih Gambar'),
                  ),
                  SizedBox(height: 10),
                ],
                if (_isUploading) CircularProgressIndicator(),
              ],
            ),
          ),
          actions: [
            if (!readOnly)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetForm();
                },
                child: Text('Batal'),
              ),
            if (!readOnly)
              ElevatedButton(
                onPressed: _isUploading ? null : _submitPromo,
                child: Text(_editingDocId == null ? 'Simpan' : 'Update'),
              ),
            if (readOnly)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Tutup'),
              ),
          ],
        ),
      ),
    );
  }

  void _showPromoOptions(DocumentSnapshot promoDoc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text('Lihat Promo'),
              onTap: () {
                Navigator.pop(context);
                _showPromoForm(promoDoc: promoDoc, readOnly: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Promo'),
              onTap: () {
                Navigator.pop(context);
                _showPromoForm(promoDoc: promoDoc);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Hapus Promo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePromo(promoDoc.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePromo(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus promo ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('promos').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promo berhasil dihapus')));
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(bool aktif) {
    return Text(
      aktif ? 'Aktif' : 'Nonaktif',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: aktif ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerAdmin(scaffoldContext: context),
      appBar: AppBar(title: Text('Kelola Promo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showPromoForm(),
              icon: Icon(Icons.add),
              label: Text('Tambah Promo'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('promos').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  final promos = snapshot.data!.docs;
                  if (promos.isEmpty) {
                    return Center(child: Text('Belum ada promo tersedia.'));
                  }

                  return ListView.builder(
                    itemCount: promos.length,
                    itemBuilder: (context, index) {
                      final promo = promos[index];
                      final data = promo.data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          onTap: () => _showPromoOptions(promo),
                          leading: Image.network(data['gambar'], width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(data['judul']),
                          subtitle: Text('Kode: ${data['kode']} | Kuota: ${data['kuota']}'),
                          trailing: _buildStatusText(data['aktif'] ?? false),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
