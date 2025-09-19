import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/home_page.dart';
import 'pages/transaksi_penjualan.dart';
import 'pages/transaksi_pembelian.dart';
import 'pages/master_beli.dart';
import 'pages/master_jual.dart';
import 'pages/pembeli.dart';
import 'pages/penjual.dart';
import 'pages/laporan_pembelian.dart';
import 'pages/laporan_penjualan.dart';
import 'pages/laporan_labarugi.dart';
// import 'pages/pengaturan.dart';
// import 'pages/bantuan.dart';

import 'widgets/sidebar.dart';

Future<void> main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(), // 0: Dashboard
    TransaksiPenjualan(), // 1: Penjualan
    TransaksiPembelian(), // 2: Pembelian
    MasterBeliPage(), // 3: Master Beli
    MasterJualPage(), // 4: Master Jual
    PembeliPage(), // 5: Pembeli
    PenjualPage(), // 6: Penjual
    LaporanPembelian(), // 7: Laporan Pembelian
    LaporanPenjualan(), // 8: Laporan Penjualan
    LaporanLabaRugiPage(),
    // Placeholder(), // 9: Laporan Laba Rugi (belum dibuat)
    // PengaturanPage(), // 10: Pengaturan
    // BantuanPage(), // 11: Bantuan
  ];

  void _onItemTapped(int index) {
    // Jika index melebihi jumlah halaman yang tersedia, arahkan ke dashboard
    if (index >= _pages.length) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

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
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Pembelian',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Harga Beli'),
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
        return 'Master Harga Pembelian';
      case 4:
        return 'Master Harga Penjualan';
      case 5:
        return 'Data Pembeli';
      case 6:
        return 'Data Penjual';
      case 7:
        return 'Laporan Pembelian';
      case 8:
        return 'Laporan Penjualan';
      case 9:
        return 'Laporan Laba Rugi';
      case 10:
        return 'Pengaturan';
      case 11:
        return 'Bantuan';
      default:
        return 'Aplikasi Kayu';
    }
  }
}

// Placeholder untuk halaman yang belum dibuat
class Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Halaman sedang dalam pengembangan')),
    );
  }
}
