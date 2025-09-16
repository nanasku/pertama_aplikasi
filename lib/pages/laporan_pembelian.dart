import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LaporanPembelian extends StatefulWidget {
  const LaporanPembelian({super.key});

  @override
  _LaporanPembelianState createState() => _LaporanPembelianState();
}

class _LaporanPembelianState extends State<LaporanPembelian> {
  List<Map<String, dynamic>> dataPembelian = [];
  List<Map<String, dynamic>> daftarPenjual = [];
  bool isLoading = true;
  String errorMessage = '';
  final DateFormat formatter = DateFormat('dd/MM/yyyy');

  // State untuk filter
  int _selectedFilterIndex = 0; // 0: Harian, 1: Bulanan, 2: Penjual
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  String? _selectedPenjualId;

  // Controller untuk dropdown bulan
  final TextEditingController _monthController = TextEditingController();

  // Fungsi untuk mengonversi string angka Indonesia ke double
  double _parseIndonesianNumber(String value) {
    if (value == null || value.isEmpty) return 0.0;

    // Hapus simbol mata uang dan spasi
    String cleanedValue = value.replaceAll('Rp', '').replaceAll(' ', '').trim();

    // Ganti titik (pemisah ribuan) dengan string kosong
    // Ganti koma (desimal) dengan titik
    cleanedValue = cleanedValue.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(cleanedValue) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDaftarPenjual();
      _loadDataPembelian();
    });
  }

  String _formatNumber(double value, {int decimalDigits = 0}) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: decimalDigits,
    ).format(value);
  }

  // Di _DetailPembelianPageState, perbaiki _formatCurrency method
  String _formatCurrency(double value) {
    // Selalu tampilkan tanpa desimal untuk currency
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // Load daftar penjual untuk dropdown
  Future<void> _loadDaftarPenjual() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/penjual'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          daftarPenjual = data.map<Map<String, dynamic>>((item) {
            return {'id': item['id'].toString(), 'nama': item['nama'] ?? '-'};
          }).toList();
        });
      }
    } catch (error) {
      print('Error loading penjual: $error');
    }
  }

  Future<void> _loadDataPembelian() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String url = '${dotenv.env['API_BASE_URL']}/pembelian';
      Map<String, String> params = {};

      // ... [kode filter yang sudah ada] ...

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Data received: ${data.length} items");

        setState(() {
          dataPembelian = data.map<Map<String, dynamic>>((item) {
            // DEBUG: Print nilai asli dari API
            print(
              "Item total from API: ${item['total']}, Type: ${item['total'].runtimeType}",
            );

            // Handle konversi nilai total dengan benar
            double totalValue = 0.0;

            if (item['total'] is double) {
              totalValue = item['total'];
            } else if (item['total'] is int) {
              totalValue = item['total'].toDouble();
            } else if (item['total'] is String) {
              String totalString = item['total'].toString().trim();

              // Coba parse langsung sebagai double
              totalValue = double.tryParse(totalString) ?? 0.0;

              // Jika parsing gagal dan mengandung titik (format Indonesia)
              if (totalValue == 0.0 && totalString.contains('.')) {
                // Hapus semua titik (pemisah ribuan) dan coba parse lagi
                String cleaned = totalString.replaceAll('.', '');
                totalValue = double.tryParse(cleaned) ?? 0.0;
              }

              // Jika masih gagal, gunakan fungsi parsing khusus
              if (totalValue == 0.0) {
                totalValue = _parseIndonesianNumber(totalString);
              }
            }

            // DEBUG: Print hasil parsing
            print("Parsed total value: $totalValue");

            return {
              'id': item['id'],
              'faktur_pemb': item['faktur_pemb'],
              'tanggal': item['created_at'],
              'nama_penjual': item['nama_penjual'] ?? '-',
              'nama_barang': item['nama_barang'] ?? '-',
              'total': totalValue,
            };
          }).toList();
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Pilih tanggal untuk filter harian
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDataPembelian(); // Panggil ulang data setelah memilih tanggal
    }
  }

  // Pilih bulan untuk filter bulanan
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _monthController.text = DateFormat('MMMM yyyy').format(_selectedMonth!);
      });
      _loadDataPembelian(); // Panggil ulang data setelah memilih bulan
    }
  }

  // Reset semua filter
  void _resetFilters() {
    setState(() {
      _selectedDate = null;
      _selectedMonth = null;
      _selectedPenjualId = null;
      _monthController.clear();
    });
    _loadDataPembelian(); // Panggil ulang data setelah reset filter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pembelian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataPembelian,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Menu Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildFilterTab('Harian', 0),
                _buildFilterTab('Bulanan', 1),
                _buildFilterTab('Penjual', 2),
              ],
            ),
          ),

          // Konten Filter berdasarkan pilihan
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildFilterContent(),
          ),

          // Tombol Reset Filter
          if (_selectedDate != null ||
              _selectedMonth != null ||
              _selectedPenjualId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset Filter'),
              ),
            ),

          // Garis pemisah
          const Divider(height: 1),

          // Data Laporan
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedFilterIndex = index;

              // Reset filter lain saat ganti tab
              if (index == 0) {
                _selectedMonth = null;
                _monthController.clear();
                _selectedPenjualId = null;
              } else if (index == 1) {
                _selectedDate = null;
                _selectedPenjualId = null;
              } else if (index == 2) {
                _selectedDate = null;
                _selectedMonth = null;
                _monthController.clear();
              }
            });

            // Panggil ulang data dengan filter baru
            _loadDataPembelian();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(title),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    switch (_selectedFilterIndex) {
      case 0: // Harian
        return Row(
          children: [
            const Text('Tanggal:'),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _selectedDate != null
                      ? formatter.format(_selectedDate!)
                      : 'Pilih Tanggal',
                ),
              ),
            ),
          ],
        );

      case 1: // Bulanan
        return Row(
          children: [
            const Text('Bulan:'),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _monthController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Pilih Bulan',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectMonth(context),
              ),
            ),
          ],
        );

      case 2: // Penjual
        return Row(
          children: [
            const Text('Penjual:'),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPenjualId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Semua Penjual'),
                  ),
                  ...daftarPenjual.map<DropdownMenuItem<String>>((penjual) {
                    return DropdownMenuItem<String>(
                      value: penjual['id'],
                      child: Text(penjual['nama']),
                    );
                  }).toList(),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedPenjualId = value;
                  });
                  _loadDataPembelian(); // Panggil ulang data saat penjual berubah
                },
              ),
            ),
          ],
        );

      default:
        return Container();
    }
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (dataPembelian.isEmpty) {
      return const Center(child: Text('Tidak ada data pembelian'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: dataPembelian.length,
            itemBuilder: (context, index) {
              final item = dataPembelian[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(item['faktur_pemb']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Penjual: ${item['nama_penjual']}'),
                      Text('Kayu: ${item['nama_barang']}'),
                      Text(
                        'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['tanggal']))}',
                      ),
                    ],
                  ),
                  trailing: Text(
                    _formatNumber(item['total']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailPembelianPage(idPembelian: item['id']),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // Total keseluruhan
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Total: ${_formatNumber(_calculateTotal())}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  double _calculateTotal() {
    return dataPembelian.fold(
      0,
      (sum, item) => sum + (item['total'] as double),
    );
  }
}

// Halaman detail pembelian (tetap sama seperti sebelumnya)
class DetailPembelianPage extends StatefulWidget {
  final int idPembelian;

  const DetailPembelianPage({super.key, required this.idPembelian});

  @override
  _DetailPembelianPageState createState() => _DetailPembelianPageState();
}

class _DetailPembelianPageState extends State<DetailPembelianPage> {
  Map<String, dynamic>? pembelianDetail;
  bool isLoading = true;
  String errorMessage = '';

  double _parseIndonesianNumber(String value) {
    if (value == null || value.isEmpty) return 0.0;

    // Hapus simbol mata uang dan spasi
    String cleanedValue = value.replaceAll('Rp', '').replaceAll(' ', '').trim();

    // Debug: print nilai yang akan di-parse
    print("Parsing Indonesian number: '$value' -> '$cleanedValue'");

    // Untuk format Indonesia: 1.800.000 → 1800000
    // Hapus semua titik (pemisah ribuan)
    if (cleanedValue.contains('.')) {
      cleanedValue = cleanedValue.replaceAll('.', '');
    }

    // Ganti koma (desimal) dengan titik jika ada
    if (cleanedValue.contains(',')) {
      cleanedValue = cleanedValue.replaceAll(',', '.');
    }

    // Parse sebagai double
    final result = double.tryParse(cleanedValue) ?? 0.0;
    print("Parsed result: $result");

    return result;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetailPembelian();
    });
  }

  Future<void> _loadDetailPembelian() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL']}/pembelian/${widget.idPembelian}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pembelianDetail = data;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat detail: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pembelian')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (pembelianDetail == null) {
      return const Center(child: Text('Data tidak ditemukan'));
    }

    // Handle konversi nilai total dengan aman
    double totalValue = 0.0;
    if (pembelianDetail!['total'] is double) {
      totalValue = pembelianDetail!['total'];
    } else if (pembelianDetail!['total'] is int) {
      totalValue = pembelianDetail!['total'].toDouble();
    } else if (pembelianDetail!['total'] is String) {
      totalValue = _parseIndonesianNumber(pembelianDetail!['total']);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('No Faktur', pembelianDetail!['faktur_pemb']),
          _buildInfoItem(
            'Tanggal',
            DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(pembelianDetail!['created_at'])),
          ),
          _buildInfoItem('Penjual', pembelianDetail!['nama_penjual'] ?? '-'),
          _buildInfoItem('Jenis Kayu', pembelianDetail!['nama_barang'] ?? '-'),
          _buildInfoItem(
            'Total',
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(totalValue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Detail Barang:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._buildDetailItems(),
        ],
      ),
    );
  }

  // Dan perbaiki juga di _buildInfoItem jika diperlukan
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Di dalam _buildDetailItems() method, perbaiki DataTable rows:
  // Di dalam _buildDetailItems() method, perbaiki format jumlah_harga_beli:
  List<Widget> _buildDetailItems() {
    if (pembelianDetail!['detail'] == null ||
        pembelianDetail!['detail'].isEmpty) {
      return [const Text('Tidak ada detail barang')];
    }

    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Grd')),
            DataColumn(label: Text('D')),
            DataColumn(label: Text('P')),
            DataColumn(label: Text('Jml')),
            DataColumn(label: Text('Vol')),
            DataColumn(label: Text('Total')),
          ],
          rows: pembelianDetail!['detail'].map<DataRow>((item) {
            // Handle konversi nilai jumlah_harga_beli dengan aman
            double jumlahHargaValue = 0.0;
            if (item['jumlah_harga_beli'] is double) {
              jumlahHargaValue = item['jumlah_harga_beli'];
            } else if (item['jumlah_harga_beli'] is int) {
              jumlahHargaValue = item['jumlah_harga_beli'].toDouble();
            } else if (item['jumlah_harga_beli'] is String) {
              // Parse langsung dari string tanpa konversi khusus
              jumlahHargaValue =
                  double.tryParse(item['jumlah_harga_beli']) ?? 0.0;
            }

            // Format angka tanpa desimal untuk diameter, panjang, jumlah, dan volume
            String formatAngkaTanpaDesimal(dynamic value) {
              if (value == null) return '-';
              if (value is num) {
                return value.toInt().toString();
              }
              if (value is String) {
                // Coba parse ke double lalu ke int
                final parsed = double.tryParse(value);
                return parsed?.toInt().toString() ?? value;
              }
              return value.toString();
            }

            // Format volume tanpa desimal
            String formatVolume(dynamic value) {
              if (value == null) return '-';
              if (value is num) {
                return value.toInt().toString();
              }
              if (value is String) {
                // Untuk volume, hapus .000 jika ada
                if (value.endsWith('.000')) {
                  return value.replaceAll('.000', '');
                }
                final parsed = double.tryParse(value);
                return parsed?.toInt().toString() ?? value;
              }
              return value.toString();
            }

            return DataRow(
              cells: [
                DataCell(Text(item['kriteria'] ?? '-')),
                DataCell(Text(formatAngkaTanpaDesimal(item['diameter']))),
                DataCell(Text(formatAngkaTanpaDesimal(item['panjang']))),
                DataCell(Text(formatAngkaTanpaDesimal(item['jumlah']))),
                DataCell(Text(formatVolume(item['volume']))),
                DataCell(
                  Text(
                    // Format tanpa simbol Rp dan tanpa pemisah ribuan
                    _formatNumber(jumlahHargaValue, decimalDigits: 0),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ];
  }

  // Tambahkan fungsi format number sederhana
  String _formatNumber(double value, {int decimalDigits = 0}) {
    final formatter = NumberFormat();
    formatter.minimumFractionDigits = decimalDigits;
    formatter.maximumFractionDigits = decimalDigits;
    return formatter.format(value);
  }
}
