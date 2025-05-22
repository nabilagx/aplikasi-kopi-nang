import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    String? password;
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
        // Update displayName
        await _user?.updateDisplayName(_nameController.text);

        // Update email dengan reauth
        if (_emailController.text != _user?.email) {
          await _reauthenticateAndUpdateEmail(_emailController.text);
        }

        await _user?.reload();
        _user = _auth.currentUser;

        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'name': _nameController.text,
          'email': _emailController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
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
          TextButton(onPressed: () { Navigator.pop(context); }, child: Text('Batal')),
          TextButton(onPressed: () { confirmed = true; Navigator.pop(context); }, child: Text('Hapus')),
        ],
      ),
    );

    if (confirmed) {
      try {
        await _user?.delete();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus akun: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengaturan Akun')),
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
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Email tidak valid';
                  return null;
                },
              ),
              SizedBox(height: 10),
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
                child: Text(showUid ? 'Sembunyikan UID' : 'Tampilkan UID'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Simpan Perubahan'),
              ),
              SizedBox(height: 20),
              if (_user!.uid != 'jATqcWGgqLcAB0PqbEY8oY65RI03')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
