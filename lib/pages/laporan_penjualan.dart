import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LaporanPenjualan extends StatefulWidget {
  const LaporanPenjualan({super.key});

  @override
  _LaporanPenjualanState createState() => _LaporanPenjualanState();
}

class _LaporanPenjualanState extends State<LaporanPenjualan> {
  List<Map<String, dynamic>> dataPenjualan = [];
  bool isLoading = true;
  String errorMessage = '';
  DateTimeRange? selectedDateRange;
  final DateFormat formatter = DateFormat('dd/MM/yyyy');

  // State untuk filter
  int _selectedFilterIndex = 0; // 0: Harian, 1: Bulanan, 2: Pembeli
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  String? _selectedPembeliId;
  List<Map<String, dynamic>> daftarPembeli = [];

  String _getLaporanTitle() {
    if (_selectedFilterIndex == 0 && _selectedDate != null) {
      return 'Laporan Penjualan Harian (${DateFormat("dd/MM/yyyy").format(_selectedDate!)})';
    } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
      return 'Laporan Penjualan Bulan ${DateFormat("MMMM yyyy", "id_ID").format(_selectedMonth!)}';
    } else if (_selectedFilterIndex == 2 && _selectedPembeliId != null) {
      final pembeli = daftarPembeli.firstWhere(
        (p) => p['id'] == _selectedPembeliId,
        orElse: () => {'nama': '-'},
      );
      return 'Laporan Penjualan oleh ${pembeli['nama']}';
    }
    return 'Laporan Penjualan';
  }

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
      _loadDaftarPembeli();
      _loadDataPenjualan();
    });
  }

  String _formatNumber(double value, {int decimalDigits = 0}) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: decimalDigits,
    ).format(value);
  }

  // Di _DetailPenjualanPageState, perbaiki _formatCurrency method
  String _formatCurrency(double value) {
    // Selalu tampilkan tanpa desimal untuk currency
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // Load daftar Pembeli untuk dropdown
  Future<void> _loadDaftarPembeli() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/pembeli'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          daftarPembeli = data.map<Map<String, dynamic>>((item) {
            return {'id': item['id'].toString(), 'nama': item['nama'] ?? '-'};
          }).toList();
        });
      }
    } catch (error) {
      print('Error loading pembeli: $error');
    }
  }

  Future<void> _loadDataPenjualan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String url = '${dotenv.env['API_BASE_URL']}/penjualan';
      Map<String, String> queryParams = {};

      // Terapkan filter sesuai tab yang aktif
      if (_selectedFilterIndex == 0 && _selectedDate != null) {
        // Filter Harian
        queryParams['filter'] = 'harian';
        queryParams['tanggal'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate!);
      } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
        // Filter Bulanan
        queryParams['filter'] = 'bulanan';
        queryParams['bulan'] = _selectedMonth!.month.toString().padLeft(2, '0');
        queryParams['tahun'] = _selectedMonth!.year.toString();
      } else if (_selectedFilterIndex == 2 && _selectedPembeliId != null) {
        // Filter Pembeli
        queryParams['filter'] = 'pembeli';
        queryParams['pembeli_id'] = _selectedPembeliId!;
      }

      // Tambahkan query string kalau ada filter
      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      }

      final response = await http.get(Uri.parse(url));
      print('DATA PENJUALAN: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          dataPenjualan = data.map<Map<String, dynamic>>((item) {
            double totalValue = 0.0;

            if (item['total'] is double) {
              totalValue = item['total'];
            } else if (item['total'] is int) {
              totalValue = item['total'].toDouble();
            } else if (item['total'] is String) {
              totalValue = _parseIndonesianNumber(item['total'].toString());
            }

            return {
              'id': item['id'],
              'faktur_penj': item['faktur_penj'],
              'tanggal': item['created_at'],
              'nama_pembeli': item['nama_pembeli'] ?? '-',
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
      _loadDataPenjualan(); // Panggil ulang data setelah memilih tanggal
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
      _loadDataPenjualan(); // Panggil ulang data setelah memilih bulan
    }
  }

  // Reset semua filter
  void _resetFilters() {
    setState(() {
      _selectedDate = null;
      _selectedMonth = null;
      _selectedPembeliId = null;
      _monthController.clear();
    });
    _loadDataPenjualan(); // Panggil ulang data setelah reset filter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataPenjualan,
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
                _buildFilterTab('Pembeli', 2),
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
              _selectedPembeliId != null)
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
                _selectedPembeliId = null;
              } else if (index == 1) {
                _selectedDate = null;
                _selectedPembeliId = null;
              } else if (index == 2) {
                _selectedDate = null;
                _selectedMonth = null;
                _monthController.clear();
              }
            });

            // Panggil ulang data dengan filter baru
            _loadDataPenjualan();
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

      case 2: // Pembeli
        return Row(
          children: [
            const Text('Pembeli:'),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPembeliId,
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
                    child: Text('Semua Pembeli'),
                  ),
                  ...daftarPembeli.map<DropdownMenuItem<String>>((pembeli) {
                    return DropdownMenuItem<String>(
                      value: pembeli['id'],
                      child: Text(pembeli['nama']),
                    );
                  }).toList(),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedPembeliId = value;
                  });
                  _loadDataPenjualan(); // Panggil ulang data saat Pembeli berubah
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

    if (dataPenjualan.isEmpty) {
      return const Center(child: Text('Tidak ada data penjualan'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: dataPenjualan.length,
            itemBuilder: (context, index) {
              final item = dataPenjualan[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(item['faktur_penj']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pembeli: ${item['nama_pembeli']}'),
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
                            DetailPenjualanPage(idPenjualan: item['id']),
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
    return dataPenjualan.fold(
      0,
      (sum, item) => sum + (item['total'] as double),
    );
  }
}

// Halaman detail Penjualan (tetap sama seperti sebelumnya)
class DetailPenjualanPage extends StatefulWidget {
  final int idPenjualan;

  const DetailPenjualanPage({super.key, required this.idPenjualan});

  @override
  _DetailPenjualanPageState createState() => _DetailPenjualanPageState();
}

class _DetailPenjualanPageState extends State<DetailPenjualanPage> {
  Map<String, dynamic>? penjualanDetail;
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
      _loadDetailPenjualan();
    });
  }

  Future<void> _loadDetailPenjualan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL']}/penjualan/${widget.idPenjualan}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          penjualanDetail = data;
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
      appBar: AppBar(title: const Text('Detail Penjualan')),
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

    if (penjualanDetail == null) {
      return const Center(child: Text('Data tidak ditemukan'));
    }

    // Handle konversi nilai total dengan aman
    double totalValue = 0.0;
    if (penjualanDetail!['total'] is double) {
      totalValue = penjualanDetail!['total'];
    } else if (penjualanDetail!['total'] is int) {
      totalValue = penjualanDetail!['total'].toDouble();
    } else if (penjualanDetail!['total'] is String) {
      totalValue = _parseIndonesianNumber(penjualanDetail!['total']);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('No Faktur', penjualanDetail!['faktur_penj']),
          _buildInfoItem(
            'Tanggal',
            DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(penjualanDetail!['created_at'])),
          ),
          _buildInfoItem('Pembeli', penjualanDetail!['nama_pembeli'] ?? '-'),
          _buildInfoItem('Jenis Kayu', penjualanDetail!['nama_barang'] ?? '-'),
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

  List<Widget> _buildDetailItems() {
    if (penjualanDetail!['detail'] == null ||
        penjualanDetail!['detail'].isEmpty) {
      return [const Text('Tidak ada detail barang')];
    }

    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Faktur')), // Tambah kolom faktur
            DataColumn(label: Text('Grd')),
            DataColumn(label: Text('D')),
            DataColumn(label: Text('P')),
            DataColumn(label: Text('Jml')),
            DataColumn(label: Text('Vol')),
            DataColumn(label: Text('Total')),
          ],
          rows: penjualanDetail!['detail'].map<DataRow>((item) {
            double jumlahHargaValue = 0.0;
            if (item['jumlah_harga_jual'] is double) {
              jumlahHargaValue = item['jumlah_harga_jual'];
            } else if (item['jumlah_harga_jual'] is int) {
              jumlahHargaValue = item['jumlah_harga_jual'].toDouble();
            } else if (item['jumlah_harga_jual'] is String) {
              jumlahHargaValue =
                  double.tryParse(item['jumlah_harga_jual']) ?? 0.0;
            }

            String formatAngka(dynamic value) {
              if (value == null) return '-';
              if (value is num) return value.toInt().toString();
              if (value is String) {
                final parsed = double.tryParse(value);
                return parsed?.toInt().toString() ?? value;
              }
              return value.toString();
            }

            return DataRow(
              cells: [
                DataCell(Text(item['faktur_penj'] ?? '')), // Faktur
                DataCell(Text(item['kriteria'] ?? '-')), // Grade
                DataCell(Text(formatAngka(item['diameter']))),
                DataCell(Text(formatAngka(item['panjang']))),
                DataCell(Text(formatAngka(item['jumlah']))),
                DataCell(Text(formatAngka(item['volume']))),
                DataCell(
                  Text(
                    NumberFormat.decimalPattern(
                      'id_ID',
                    ).format(jumlahHargaValue.toInt()),
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
