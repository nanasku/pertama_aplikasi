import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Customer {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final DateTime joinDate;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.joinDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      joinDate: DateTime.parse(map['joinDate']),
    );
  }
}

class CustomersPage extends StatefulWidget {
  @override
  _CustomersPageState createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> customers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Data contoh
    _loadSampleData();
  }

  void _loadSampleData() {
    setState(() {
      customers = [
        Customer(
          id: '1',
          name: 'Budi Santoso',
          address: 'Jl. Merdeka No. 123, Jakarta',
          phone: '081234567890',
          email: 'budi.santoso@email.com',
          joinDate: DateTime(2024, 1, 15),
        ),
        Customer(
          id: '2',
          name: 'Siti Rahayu',
          address: 'Jl. Sudirman No. 456, Bandung',
          phone: '082345678901',
          email: 'siti.rahayu@email.com',
          joinDate: DateTime(2024, 2, 20),
        ),
        Customer(
          id: '3',
          name: 'Ahmad Wijaya',
          address: 'Jl. Gatot Subroto No. 789, Surabaya',
          phone: '083456789012',
          email: 'ahmad.wijaya@email.com',
          joinDate: DateTime(2024, 3, 10),
        ),
        Customer(
          id: '4',
          name: 'Dewi Lestari',
          address: 'Jl. Thamrin No. 321, Medan',
          phone: '084567890123',
          email: 'dewi.lestari@email.com',
          joinDate: DateTime(2024, 4, 5),
        ),
        Customer(
          id: '5',
          name: 'Rudi Hermawan',
          address: 'Jl. Asia Afrika No. 654, Yogyakarta',
          phone: '085678901234',
          email: 'rudi.hermawan@email.com',
          joinDate: DateTime(2024, 5, 12),
        ),
      ];
    });
  }

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) {
      return customers;
    }
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.phone.contains(_searchQuery) ||
          customer.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addCustomer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDialog(
          onSave: (customer) {
            setState(() {
              customers.add(customer);
            });
          },
        );
      },
    );
  }

  void _editCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDialog(
          customer: customer,
          onSave: (editedCustomer) {
            setState(() {
              final index = customers.indexWhere(
                (c) => c.id == editedCustomer.id,
              );
              if (index != -1) {
                customers[index] = editedCustomer;
              }
            });
          },
        );
      },
    );
  }

  void _deleteCustomer(String id) {
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
                setState(() {
                  customers.removeWhere((customer) => customer.id == id);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pelanggan berhasil dihapus')),
                );
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
            onPressed: _loadSampleData,
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
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Customer Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pelanggan: ${filteredCustomers.length}',
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
            child: filteredCustomers.isEmpty
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
                            onPressed: _addCustomer,
                            child: Text('Tambah Pelanggan Pertama'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return CustomerCard(
                        customer: customer,
                        onEdit: () => _editCustomer(customer),
                        onDelete: () => _deleteCustomer(customer.id),
                        onView: () => _viewCustomerDetails(customer),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
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
            customer.name[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(customer.phone),
            SizedBox(height: 2),
            Text(
              customer.address,
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _addressController.text = widget.customer!.address;
      _phoneController.text = widget.customer!.phone;
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
                controller: _nameController,
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
                controller: _phoneController,
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
                controller: _addressController,
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
                          id:
                              widget.customer?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _nameController.text,
                          address: _addressController.text,
                          phone: _phoneController.text,
                          email: _emailController.text,
                          joinDate: widget.customer?.joinDate ?? DateTime.now(),
                        );
                        widget.onSave(customer);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.customer == null
                                  ? 'Pelanggan berhasil ditambahkan'
                                  : 'Pelanggan berhasil diperbarui',
                            ),
                          ),
                        );
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
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                customer.name[0].toUpperCase(),
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
              customer.name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Bergabung: ${_formatDate(customer.joinDate)}',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
          SizedBox(height: 24),
          _buildDetailItem(Icons.phone, customer.phone),
          _buildDetailItem(
            Icons.email,
            customer.email.isNotEmpty ? customer.email : '-',
          ),
          _buildDetailItem(Icons.location_on, customer.address),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Aksi telepon
                },
                icon: Icon(Icons.call),
                label: Text('Telepon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Aksi WhatsApp
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
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
