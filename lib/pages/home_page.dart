import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Card stats
            Row(
              children: [
                _buildStatCard(
                  'Total Penjualan',
                  '15',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                SizedBox(width: 16),
                _buildStatCard('Produk', '6', Icons.inventory, Colors.green),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Pelanggan', '8', Icons.people, Colors.orange),
                SizedBox(width: 16),
                _buildStatCard(
                  'Pendapatan',
                  'Rp 5.250.000',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildActivityItem('Penjualan baru', '10 menit lalu'),
                  _buildActivityItem('Produk ditambahkan', '1 jam lalu'),
                  _buildActivityItem('Pelanggan baru', '2 jam lalu'),
                  _buildActivityItem('Pembayaran diterima', '5 jam lalu'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.notifications, color: Colors.blue),
        ),
        title: Text(activity),
        subtitle: Text(time),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
