import 'package:flutter/material.dart';

class MasterJualPage extends StatefulWidget {
  const MasterJualPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<MasterJualPage> {
  List<Map<String, dynamic>> products = [
    {
      'id': 1,
      'name': 'Kayu Alba',
      'prices': {
        'Rijek 1': '150000',
        'Rijek 2': '200000',
        'Standar': '250000',
        'Super A': '300000',
        'Super B': '350000',
        'Super C': '400000',
      },
    },
    {
      'id': 2,
      'name': 'Kayu Sengon',
      'prices': {
        'Rijek 1': '120000',
        'Rijek 2': '180000',
        'Standar': '220000',
        'Super A': '280000',
        'Super B': '320000',
        'Super C': '380000',
      },
    },
  ];

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
                        labelText: 'Harga $priceKey',
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
              onPressed: () {
                // Update product data
                setState(() {
                  product['name'] = nameController.text;
                  controllers.forEach((key, controller) {
                    product['prices'][key] = controller.text;
                  });
                });
                Navigator.of(context).pop();
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
                        labelText: 'Harga $priceKey',
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
              onPressed: () {
                // Add new product
                Map<String, String> prices = {};
                controllers.forEach((key, controller) {
                  prices[key] = controller.text;
                });

                setState(() {
                  products.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'name': nameController.text,
                    'prices': prices,
                  });
                });
                Navigator.of(context).pop();
              },
              child: Text('Simpan'),
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
          IconButton(icon: Icon(Icons.add), onPressed: _showAddProductDialog),
        ],
      ),
      body: ListView.builder(
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
        trailing: Icon(Icons.edit),
        onTap: () {
          _showEditProductDialog(product);
        },
      ),
    );
  }
}
