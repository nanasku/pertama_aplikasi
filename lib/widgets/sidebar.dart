import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const Sidebar({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
  }) : super(key: key);

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
          _buildListTile(context, Icons.shopping_cart, 'Penjualan', 1),
          _buildListTile(context, Icons.inventory, 'Produk', 2),
          _buildListTile(context, Icons.people, 'Pelanggan', 3),
          Divider(),
          _buildListTile(context, Icons.settings, 'Pengaturan', 4),
          _buildListTile(context, Icons.help, 'Bantuan', 5),
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
    final bool isSelected = selectedIndex == index;

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
        Navigator.pop(context); // Close the drawer
        onItemSelected(index);
      },
    );
  }
}
