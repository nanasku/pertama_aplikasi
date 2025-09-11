import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/transaksi_penjualan.dart';
import 'pages/transaksi_pembelian.dart';
import 'pages/master_beli.dart';
import 'pages/master_jual.dart';
import 'pages/pembeli.dart';
import 'pages/penjual.dart';
// import 'pages/pengaturan.dart';
// import 'pages/bantuan.dart';

import 'widgets/sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kayu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(), // 0: Dashboard
    TransaksiPenjualan(), // 1: Penjualan
    TransaksiPembelian(), // 2: Pembelian (ganti jika ada)
    MasterBeliPage(), // 3: Master Beli
    MasterJualPage(), // 4: Master Jual
    PembeliPage(), // 5: Pembeli
    PenjualPage(), // 6: Penjual
    // PengaturanPage(),        // 7: Pengaturan
    // BantuanPage(),           // 8: Bantuan
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex != 0)
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () => _onItemTapped(0),
              tooltip: 'Kembali ke Home',
            ),
        ],
      ),
      drawer: Sidebar(
        onItemSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Penjualan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelanggan'),
        ],
        currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => _onItemTapped(index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Transaksi Penjualan';
      case 2:
        return 'Transaksi Pembelian';
      case 3:
        return 'Master Pembelian';
      case 4:
        return 'Master Penjualan';
      case 5:
        return 'Data Pembeli';
      case 6:
        return 'Data Penjual';
      case 7:
        return 'Pengaturan';
      case 8:
        return 'Bantuan';
      default:
        return 'Aplikasi Kayu';
    }
  }
}
