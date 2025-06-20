import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopinang/widgets/drawer_admin.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';

class PengaturanAkunPage extends StatefulWidget {
  @override
  _PengaturanAkunPageState createState() => _PengaturanAkunPageState();
}

class _PengaturanAkunPageState extends State<PengaturanAkunPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  String role = "Loading...";
  bool showUid = false;

  final Color navyBlue = Color(0xFF0D47A1);
  final Color softBlue = Color(0xFFEAF4FB);

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _nameController = TextEditingController(text: _user?.displayName ?? '');
    _emailController = TextEditingController(text: _user?.email ?? '');
    _loadUserRole();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      setState(() {
        role = doc.data()?['role'] ?? 'Tidak diketahui';
      });
    } else {
      setState(() {
        role = 'Tidak ditemukan';
      });
    }
  }

  Future<void> _reauthenticateAndUpdateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return;

      final currentEmail = user.email!;
      final password = await _showPasswordDialog();
      if (password == null) return;

      final credential = EmailAuthProvider.credential(email: currentEmail, password: password);
      await user.reauthenticateWithCredential(credential);
      await user.updateEmail(newEmail);
    } catch (e) {
      throw Exception("Gagal update email: ${e.toString()}");
    }
  }

  Future<String?> _showPasswordDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        final _passwordController = TextEditingController();
        return AlertDialog(
          title: Text('Verifikasi Ulang'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Masukkan Password Anda'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _passwordController.text),
              child: Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _user?.updateDisplayName(_nameController.text);

        if (_emailController.text != _user?.email) {
          await _reauthenticateAndUpdateEmail(_emailController.text);
        }

        await _user?.reload();
        _user = _auth.currentUser;

        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'name': _nameController.text,
          'email': _emailController.text,
        });

        showKopiNangAlert(
          context,
          "Profil diperbarui",
          "Profil berhasil diperbarui",
          type: 'success',
        );
      } catch (e) {
        showKopiNangAlert(
          context,
          "Gagal",
          "Gagal memperbarui profil: $e",
          type: 'error',
        );

      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Akun'),
        content: Text('Apakah Anda yakin ingin menghapus akun ini? Data tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          TextButton(
              onPressed: () {
                confirmed = true;
                Navigator.pop(context);
              },
              child: Text('Hapus')),
        ],
      ),
    );

    if (confirmed) {
      try {
        await _user?.delete();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        showKopiNangAlert(
          context,
          "Gagal",
          "Gagal menghapus akun: $e",
          type: 'error',
        );

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBlue,
      appBar: AppBar(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        title: Text('Pengaturan Akun'),
      ),
      drawer: DrawerAdmin(
        onSelectMenu: (menu) {
          Navigator.pop(context);
        },
        scaffoldContext: context,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _user == null
            ? Center(child: Text('Tidak ada user yang login'))
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Email tidak valid';
                  return null;
                },
              ),
              SizedBox(height: 12),
              ListTile(
                title: Text('Role: $role'),
              ),
              if (showUid)
                ListTile(
                  title: Text('UID: ${_user!.uid}'),
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    showUid = !showUid;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: navyBlue,
                ),
                child: Text(showUid ? 'Sembunyikan UID' : 'Tampilkan UID'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _updateProfile,
                child: const Text('Simpan Perubahan'),
              ),
              SizedBox(height: 20),
              if (_user!.uid != 'jATqcWGgqLcAB0PqbEY8oY65RI03')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _confirmDeleteAccount,
                  child: Text('Hapus Akun'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
