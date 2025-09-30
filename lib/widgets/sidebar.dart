import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Sidebar extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const Sidebar({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int? _expandedIndex;
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService.getUserProfile(1);
  }

  void _handleExpansion(int index, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedIndex = index;
      } else if (_expandedIndex == index) {
        _expandedIndex = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // DrawerHeader dengan data dari database
          FutureBuilder<User>(
            future: _userFuture,
            builder: (context, snapshot) {
              // Default values jika data belum loaded
              String companyName = 'Kayu App';
              String? profileImage;

              if (snapshot.hasData) {
                final user = snapshot.data!;
                companyName = user.companyName;
                profileImage = user.profileImage;
              }
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  // Hapus background image atau gunakan AssetImage yang benar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image dari database
                    // Ganti bagian CircleAvatar dengan:
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.business, color: Colors.blue, size: 30),
                    ),
                    const SizedBox(height: 10),
                    // Company Name dari database
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Email (jika ingin ditampilkan)
                    if (snapshot.hasData)
                      Text(
                        snapshot.data!.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    // Subtitle
                    const Text(
                      'TPKApp Versi 01.00',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),

          _buildListTile(context, Icons.dashboard, 'Dashboard', 0),

          ExpansionTile(
            leading: Icon(Icons.inventory, color: Colors.grey[700]),
            title: const Text(
              'Master Data',
              style: TextStyle(color: Colors.black),
            ),
            initiallyExpanded: _expandedIndex == 0,
            onExpansionChanged: (expanded) => _handleExpansion(0, expanded),
            children: [
              _buildSubMenuTile(context, 'Data Harga Beli', 3),
              _buildSubMenuTile(context, 'Data Harga Jual', 4),
              _buildSubMenuTile(context, 'Data Pembeli', 5),
              _buildSubMenuTile(context, 'Data Penjual', 6),
              _buildSubMenuTile(context, 'Data Karyawan', 12),
            ],
          ),

          _buildListTile(
            context,
            Icons.shopping_cart,
            'Transaksi Penjualan',
            1,
          ),
          _buildListTile(context, Icons.inventory, 'Transaksi Pembelian', 2),

          ExpansionTile(
            leading: Icon(Icons.bar_chart, color: Colors.grey[700]),
            title: const Text('Laporan', style: TextStyle(color: Colors.black)),
            initiallyExpanded: _expandedIndex == 1,
            onExpansionChanged: (expanded) => _handleExpansion(1, expanded),
            children: [
              _buildSubMenuTile(context, 'Laporan Pembelian', 7),
              _buildSubMenuTile(context, 'Laporan Penjualan', 8),
              _buildSubMenuTile(context, 'Laporan Laba Rugi', 9),
              _buildSubMenuTile(context, 'Laporan Stok', 10),
            ],
          ),

          ExpansionTile(
            leading: Icon(Icons.settings, color: Colors.grey[700]),
            title: const Text(
              'Pengaturan',
              style: TextStyle(color: Colors.black),
            ),
            initiallyExpanded: _expandedIndex == 2,
            onExpansionChanged: (expanded) => _handleExpansion(2, expanded),
            children: [
              _buildSubMenuTile(context, 'Profil Pengguna', 11),
              _buildSubMenuTile(context, 'Konfigurasi Database', 13),
            ],
          ),

          _buildListTile(context, Icons.help, 'Bantuan', 14),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    final bool isSelected = widget.selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        widget.onItemSelected(index);
      },
    );
  }

  Widget _buildSubMenuTile(BuildContext context, String title, int index) {
    final bool isSelected = widget.selectedIndex == index;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0),
      leading: Icon(
        Icons.circle,
        size: 8,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        widget.onItemSelected(index);
      },
    );
  }
}
