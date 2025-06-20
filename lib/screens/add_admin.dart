import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kopinang/widgets/kopi_nang_alert.dart';
import 'package:kopinang/widgets/drawer_admin.dart';

class AddAdminPage extends StatefulWidget {
  @override
  _AddAdminPageState createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;


  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final String superAdminUid = 'jATqcWGgqLcAB0PqbEY8oY65RI03';

  bool get isSuperAdmin => _auth.currentUser?.uid == superAdminUid;

  Future<void> _addAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showKopiNangAlert(
        context,
        'Peringatan',
        'Emal dan pasword tidak boleh kosong',
        type: 'warning',
      );
      return;
    }

    try {
      // Cek apakah email sudah terdaftar di Firestore 'users'
      final existing = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        showKopiNangAlert(
          context,
          'User sudah terdaftar',
          'User dengan email ini sudah terdaftar',
          type: 'warning',
        );
        return;
      }

      // Buat user baru di Firebase Auth
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = userCredential.user?.uid;

      if (newUid == null) {
        throw 'Gagal mendapatkan UID user baru';
      }

      // Simpan data admin di Firestore
      await _firestore.collection('users').doc(newUid).set({
        'email': email,
        'name': '',
        'role': 'admin',
        'uid': newUid,
      });

      _emailController.clear();
      _passwordController.clear();

      showKopiNangAlert(
        context,
        'Admin ditambahkan',
        'Admin baru berhasil ditambahkan',
        type: 'success',
      );
    } on FirebaseAuthException catch (e) {
      showKopiNangAlert(
        context,
        'Error',
        'Error Firebaseauth: ${e.message}',
        type: 'error',
      );
    } catch (e) {
      showKopiNangAlert(
        context,
        'Gagal',
        'Gagal menambah admin: $e',
        type: 'error',
      );
    }
  }

  Future<void> _deleteAdmin(String docId, String uid) async {
    try {
      // Hapus user dari Firebase Auth juga
      await _auth.currentUser?.getIdToken();

      // Admin hanya bisa dihapus jika bukan super admin
      if (uid == superAdminUid) {
        showKopiNangAlert(
          context,
          'Dilarang',
          'Super admin tidak bisa dihapus',
          type: 'error',
        );
        return;
      }

      // Hapus dari Firestore
      await _firestore.collection('users').doc(docId).delete();
      showKopiNangAlert(
        context,
        'Admin dihapus',
        'Admin berhasil dihapus',
        type: 'success',
      );
    } catch (e) {
      showKopiNangAlert(
        context,
        'Gagal dihapus',
        'Gagal menghapsu admin $e',
        type: 'error',
      );
    }
  }

  Future<void> _showEditNameDialog(String docId, String currentName) async {
    final _editController = TextEditingController(text: currentName);

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Nama Admin'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              labelText: 'Nama Admin',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Simpan'),
              onPressed: () async {
                final newName = _editController.text.trim();
                if (newName.isEmpty) {
                  showKopiNangAlert(
                    context,
                    'Peringatan',
                    'Nama tidak boleh kosong',
                    type: 'warning',
                  );
                  return;
                }
                try {
                  await _firestore
                      .collection('users')
                      .doc(docId)
                      .update({'name': newName});
                  Navigator.of(context).pop();
                  showKopiNangAlert(
                    context,
                    'Nama diperbarui',
                    'Nama admin berhasil diperbarui',
                    type: 'success',
                  );
                } catch (e) {
                  showKopiNangAlert(
                    context,
                    'Gagal',
                    'Gagal memperbarui nama: $e',
                    type: 'error',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSuperAdmin) {
      return Scaffold(
        drawer: DrawerAdmin(scaffoldContext: context),
        backgroundColor: Color(0xFFEAF4FB),
        appBar: AppBar(
          backgroundColor: Color(0xFF0D47A1),
          title: Text('Kelola Admin'),
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Anda bukan super admin')),
      );
    }

    return Scaffold(
      drawer: DrawerAdmin(scaffoldContext: context),
      backgroundColor: Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        title: Text('Kelola Admin'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email admin baru',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Tambah Admin'),
            ),
            Divider(height: 32, color: Colors.grey[400]),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'admin')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(child: Text('Belum ada admin'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;

                      final name = data['name'] ?? '';
                      final email = data['email'] ?? '';
                      final uid = data['uid'] ?? '';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            name.isNotEmpty ? name : '-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(email),
                          trailing: isSuperAdmin
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: Color(0xFF0D47A1)),
                                tooltip: 'Edit Nama',
                                onPressed: () =>
                                    _showEditNameDialog(docId, name),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.red.shade700),
                                tooltip: 'Hapus Admin',
                                onPressed: () {
                                  if (uid == superAdminUid) {
                                    showKopiNangAlert(
                                      context,
                                      'Gagal',
                                      'Super admin tidak bisa dihapus',
                                      type: 'error',
                                    );
                                    return;
                                  }
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('Konfirmasi Hapus'),
                                      content: Text(
                                          'Apakah yakin ingin menghapus admin ini?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Batal'),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                        ),
                                        TextButton(
                                          child: Text('Hapus'),
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            _deleteAdmin(docId, uid);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

