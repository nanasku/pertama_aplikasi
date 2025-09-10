import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Tambah produk baru
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildProductCard('Rijek 1', 'Diameter 10-14 cm', 'Rp 150.000'),
          _buildProductCard('Rijek 2', 'Diameter 15-19 cm', 'Rp 200.000'),
          _buildProductCard('Standar', 'Diameter 20-24 cm', 'Rp 250.000'),
          _buildProductCard('Super A', 'Diameter 25-29 cm', 'Rp 300.000'),
          _buildProductCard('Super B', 'Diameter 30-34 cm', 'Rp 350.000'),
          _buildProductCard('Super C', 'Diameter 35+ cm', 'Rp 400.000'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tambah produk baru
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(String name, String description, String price) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.forest, color: Colors.green),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Text(price, style: TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {
          // Edit produk
        },
      ),
    );
  }
}
