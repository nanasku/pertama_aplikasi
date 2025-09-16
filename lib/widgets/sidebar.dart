import 'package:flutter/material.dart';

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
  int? _expandedIndex; // menyimpan index ExpansionTile yang sedang dibuka

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
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.business, color: Colors.blue, size: 30),
                ),
                SizedBox(height: 10),
                Text(
                  'Kayu App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manajemen Penjualan',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildListTile(context, Icons.dashboard, 'Dashboard', 0),
          _buildListTile(
            context,
            Icons.shopping_cart,
            'Transaksi Penjualan',
            1,
          ),
          _buildListTile(
            context,
            Icons.shopping_cart,
            'Transaksi Pembelian',
            2,
          ),

          ExpansionTile(
            leading: Icon(Icons.inventory, color: Colors.grey[700]),
            title: Text('Master Data', style: TextStyle(color: Colors.black)),
            initiallyExpanded: _expandedIndex == 0,
            onExpansionChanged: (expanded) => _handleExpansion(0, expanded),
            children: [
              _buildSubMenuTile(context, 'Data Harga Beli', 3),
              _buildSubMenuTile(context, 'Data Harga Jual', 4),
              _buildSubMenuTile(context, 'Data Pembeli', 5),
              _buildSubMenuTile(context, 'Data Penjual', 6),
            ],
          ),

          ExpansionTile(
            leading: Icon(Icons.bar_chart, color: Colors.grey[700]),
            title: Text('Laporan', style: TextStyle(color: Colors.black)),
            initiallyExpanded: _expandedIndex == 1,
            onExpansionChanged: (expanded) => _handleExpansion(1, expanded),
            children: [
              _buildSubMenuTile(context, 'Laporan Pembelian', 7),
              _buildSubMenuTile(context, 'Laporan Penjualan', 8),
              _buildSubMenuTile(context, 'Laporan Laba Rugi', 9),
            ],
          ),

          ExpansionTile(
            leading: Icon(Icons.settings, color: Colors.grey[700]),
            title: Text('Pengaturan', style: TextStyle(color: Colors.black)),
            initiallyExpanded: _expandedIndex == 2,
            onExpansionChanged: (expanded) => _handleExpansion(2, expanded),
            children: [
              _buildSubMenuTile(context, 'Profil Pengguna', 10),
              _buildSubMenuTile(context, 'Preferensi', 11),
              _buildSubMenuTile(context, 'Keamanan', 12),
            ],
          ),

          _buildListTile(context, Icons.help, 'Bantuan', 13),
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
        Navigator.pop(context); // tutup drawer
        widget.onItemSelected(index);
      },
    );
  }

  Widget _buildSubMenuTile(BuildContext context, String title, int index) {
    final bool isSelected = widget.selectedIndex == index;
    return ListTile(
      contentPadding: EdgeInsets.only(left: 72.0, right: 16.0),
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
