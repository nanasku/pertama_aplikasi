import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MasterJualPage extends StatefulWidget {
  const MasterJualPage({Key? key}) : super(key: key);

  @override
  _MasterJualPageState createState() => _MasterJualPageState();
}

class _MasterJualPageState extends State<MasterJualPage> {
  // ✅ Dipindahkan ke atas agar bisa diakses di semua fungsi
  final Map<String, String> priceLabels = {
    'Rijek 1': 'Harga Rijek 1 (D 10-14)',
    'Rijek 2': 'Harga Rijek 2 (D 15-19)',
    'Standar': 'Harga Standar (D 20 Up)',
    'Super A': 'Harga Super A Custom',
    'Super B': 'Harga Super B Custom',
    'Super C': 'Harga Super C (D 25 Up)',
  };

  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String errorMessage = '';

  // Base URL untuk API (sesuaikan dengan environment Anda)
  static final String baseUrl =
      dotenv.env['API_BASE_URL']!; // Ganti dengan URL server Anda

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fungsi untuk mengambil data produk dari API
  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/harga-jual'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  // Fungsi untuk menambah produk baru
  Future<void> _addProduct(Map<String, dynamic> newProduct) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/harga-jual'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': newProduct['name'],
          'prices': newProduct['prices'],
        }),
      );

      if (response.statusCode == 201) {
        // Refresh data setelah berhasil menambah
        _fetchProducts();
      } else {
        throw Exception('Gagal menambah produk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Fungsi untuk mengupdate produk
  Future<void> _updateProduct(Map<String, dynamic> updatedProduct) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/harga-jual/${updatedProduct['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': updatedProduct['name'],
          'prices': updatedProduct['prices'],
        }),
      );

      if (response.statusCode == 200) {
        // Refresh data setelah berhasil update
        _fetchProducts();
      } else {
        throw Exception('Gagal mengupdate produk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Fungsi untuk menghapus produk
  Future<void> _deleteProduct(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/harga-jual/$id'));

      if (response.statusCode == 200) {
        // Refresh data setelah berhasil menghapus
        _fetchProducts();
      } else {
        throw Exception('Gagal menghapus produk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    Map<String, TextEditingController> controllers = {};

    // Initialize controllers with current values
    product['prices'].forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });

    TextEditingController nameController = TextEditingController(
      text: product['name'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Harga Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kayu',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ...product['prices'].keys.map((priceKey) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: controllers[priceKey],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: priceLabels[priceKey] ?? 'Harga $priceKey',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update product data
                final updatedProduct = {
                  'id': product['id'],
                  'name': nameController.text,
                  'prices': {},
                };

                controllers.forEach((key, controller) {
                  updatedProduct['prices'][key] = controller.text;
                });

                try {
                  await _updateProduct(updatedProduct);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengupdate produk: $e')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductDialog() {
    Map<String, TextEditingController> controllers = {};
    List<String> priceTypes = [
      'Rijek 1',
      'Rijek 2',
      'Standar',
      'Super A',
      'Super B',
      'Super C',
    ];

    // Initialize controllers with empty values
    for (var priceType in priceTypes) {
      controllers[priceType] = TextEditingController();
    }

    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kayu',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ...priceTypes.map((priceKey) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: controllers[priceKey],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: priceLabels[priceKey] ?? 'Harga $priceKey',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Add new product
                Map<String, String> prices = {};
                controllers.forEach((key, controller) {
                  prices[key] = controller.text;
                });

                final newProduct = {
                  'name': nameController.text,
                  'prices': prices,
                };

                try {
                  await _addProduct(newProduct);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menambah produk: $e')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Produk'),
          content: Text('Apakah Anda yakin ingin menghapus $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _deleteProduct(id);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus produk: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Produk'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchProducts),
          IconButton(icon: Icon(Icons.add), onPressed: _showAddProductDialog),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : products.isEmpty
          ? Center(child: Text('Tidak ada data produk'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.forest, color: Colors.green),
        ),
        title: Text(
          product['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rijek 1: Rp ${product['prices']['Rijek 1']}'),
            Text('Rijek 2: Rp ${product['prices']['Rijek 2']}'),
            Text('Standar: Rp ${product['prices']['Standar']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditProductDialog(product);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(product['id'], product['name']);
              },
            ),
          ],
        ),
      ),
    );
  }
}
