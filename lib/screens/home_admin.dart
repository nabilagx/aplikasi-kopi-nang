import 'package:flutter/material.dart';
import 'package:kopinang/widgets/drawer_admin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({Key? key}) : super(key: key);

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  String _selectedMenu = 'Dashboard';

  void _onSelectMenu(String menu) {
    Navigator.pop(context);
    setState(() {
      _selectedMenu = menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - $_selectedMenu'),
      ),
      drawer: DrawerAdmin(
        onSelectMenu: _onSelectMenu,
        scaffoldContext: context,
      ),
      body: Center(
        child: Text(
          'Halaman $_selectedMenu',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
