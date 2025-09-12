import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Customer {
  final int id;
  final String nama;
  final String alamat;
  final String telepon;
  final String email;
  final DateTime? createdAt; // nullable

  Customer({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.email,
    this.createdAt, // optional
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      nama: json['nama'],
      alamat: json['alamat'] ?? '',
      telepon: json['telepon'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class PenjualPage extends StatefulWidget {
  @override
  PenjualPageState createState() => PenjualPageState();
}

class PenjualPageState extends State<PenjualPage> {
  List<Customer> customers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String _errorMessage = '';

  // Base URL untuk API
  static final String baseUrl = '${dotenv.env['API_BASE_URL']}/penjual';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String url = baseUrl;
      if (_searchQuery.isNotEmpty) {
        url += '?search=${Uri.encodeQueryComponent(_searchQuery)}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          customers = data.map((json) => Customer.fromJson(json)).toList();
        });
      } else {
        throw Exception(
          'Gagal memuat pelanggan (Kode: ${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data pelanggan')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCustomer(Customer customer) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama': customer.nama,
          'alamat': customer.alamat,
          'telepon': customer.telepon,
          'email': customer.email,
        }),
      );

      if (response.statusCode == 201) {
        _loadCustomers(); // Reload data setelah berhasil menambah
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pelanggan berhasil ditambahkan')),
        );
      } else {
        throw Exception('Failed to add customer: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan pelanggan: $e')),
      );
    }
  }

  Future<void> _updateCustomer(Customer customer) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${customer.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama': customer.nama,
          'alamat': customer.alamat,
          'telepon': customer.telepon,
          'email': customer.email,
        }),
      );

      if (response.statusCode == 200) {
        _loadCustomers(); // Reload data setelah berhasil update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pelanggan berhasil diperbarui')),
        );
      } else {
        throw Exception('Failed to update customer: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui pelanggan: $e')),
      );
    }
  }

  Future<void> _deleteCustomer(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        _loadCustomers(); // Reload data setelah berhasil delete
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pelanggan berhasil dihapus')));
      } else {
        throw Exception('Failed to delete customer: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus pelanggan: $e')));
    }
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDialog(onSave: _addCustomer);
      },
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDialog(customer: customer, onSave: _updateCustomer);
      },
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Pelanggan'),
          content: Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteCustomer(id);
                Navigator.of(context).pop();
              },
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _viewCustomerDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CustomerDetailSheet(customer: customer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Pelanggan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pelanggan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadCustomers();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                _loadCustomers();
              },
            ),
          ),

          // Loading and Error States
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
            ),

          // Customer Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pelanggan: ${customers.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Text(
                    'Hasil pencarian: "$_searchQuery"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10),

          // Customers List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada pelanggan'
                              : 'Tidak ada hasil pencarian',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isEmpty)
                          TextButton(
                            onPressed: _showAddCustomerDialog,
                            child: Text('Tambah Pelanggan Pertama'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return CustomerCard(
                        customer: customer,
                        onEdit: () => _showEditCustomerDialog(customer),
                        onDelete: () => _showDeleteConfirmation(customer.id),
                        onView: () => _viewCustomerDetails(customer),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        child: Icon(Icons.add),
        tooltip: 'Tambah Pelanggan',
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const CustomerCard({
    Key? key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer.nama[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.nama,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(customer.telepon),
            SizedBox(height: 2),
            Text(
              customer.alamat,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') onView();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(value: 'view', child: Text('Lihat Detail')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
        onTap: onView,
      ),
    );
  }
}

class CustomerDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const CustomerDialog({Key? key, this.customer, required this.onSave})
    : super(key: key);

  @override
  _CustomerDialogState createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _namaController.text = widget.customer!.nama;
      _alamatController.text = widget.customer!.alamat;
      _teleponController.text = widget.customer!.telepon;
      _emailController.text = widget.customer!.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pelanggan harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _teleponController,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon harus diisi';
                  }
                  if (value.length < 10) {
                    return 'Nomor telepon minimal 10 digit';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (opsional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !value.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Batal'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final customer = Customer(
                          id: widget.customer?.id ?? 0,
                          nama: _namaController.text,
                          alamat: _alamatController.text,
                          telepon: _teleponController.text,
                          email: _emailController.text,
                          createdAt:
                              widget.customer?.createdAt ?? DateTime.now(),
                        );
                        widget.onSave(customer);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      widget.customer == null ? 'Simpan' : 'Perbarui',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerDetailSheet extends StatelessWidget {
  final Customer customer;

  const CustomerDetailSheet({Key? key, required this.customer})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7, // Tinggi awal modal
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 40,
                    child: Text(
                      customer.nama[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    customer.nama,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    customer.email.isNotEmpty
                        ? customer.email
                        : 'Tidak ada email',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 24),
                Divider(),
                _buildDetailItem('Telepon', customer.telepon, Icons.phone),
                _buildDetailItem('Alamat', customer.alamat, Icons.location_on),
                _buildDetailItem(
                  'Tanggal Bergabung',
                  '${customer.createdAt?.day}/${customer.createdAt?.month}/${customer.createdAt?.year}',
                  Icons.calendar_today,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final phone = customer.telepon;
                        if (phone.isNotEmpty) {
                          final Uri telUri = Uri(scheme: 'tel', path: phone);
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tidak dapat melakukan panggilan.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.call),
                      label: Text('Telepon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final phone = customer.telepon.replaceFirst(
                          RegExp(r'^0'),
                          '62',
                        );
                        final Uri whatsappUri = Uri.parse(
                          'https://wa.me/$phone',
                        );
                        if (await canLaunchUrl(whatsappUri)) {
                          await launchUrl(whatsappUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal membuka WhatsApp')),
                          );
                        }
                      },
                      icon: Icon(Icons.chat),
                      label: Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
