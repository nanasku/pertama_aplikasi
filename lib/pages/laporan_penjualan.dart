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
      _loadDataPenjualan();
    });
  }

  Future<void> _loadDataPenjualan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String url = '${dotenv.env['API_BASE_URL']}/penjualan';

      // Tambahkan filter tanggal jika dipilih
      if (selectedDateRange != null) {
        final startDate = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange!.start);
        final endDate = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);
        url += '?start_date=$startDate&end_date=$endDate';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          dataPenjualan = data.map<Map<String, dynamic>>((item) {
            // Handle konversi nilai total dengan aman
            double totalValue = 0.0;
            if (item['total'] is double) {
              totalValue = item['total'];
            } else if (item['total'] is int) {
              totalValue = item['total'].toDouble();
            } else if (item['total'] is String) {
              totalValue = _parseIndonesianNumber(item['total']);
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );

    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
      _loadDataPenjualan();
    }
  }

  void _clearDateFilter() {
    setState(() {
      selectedDateRange = null;
    });
    _loadDataPenjualan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          if (selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Hapus Filter Tanggal',
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Pilih Rentang Tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataPenjualan,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
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

    if (dataPenjualan.isEmpty) {
      return const Center(child: Text('Tidak ada data penjualan'));
    }

    return Column(
      children: [
        if (selectedDateRange != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Periode: ${formatter.format(selectedDateRange!.start)} - ${formatter.format(selectedDateRange!.end)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(item['total']),
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_calculateTotal())}',
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

// Halaman detail Penjualan
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
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Diameter')),
            DataColumn(label: Text('Panjang')),
            DataColumn(label: Text('Jumlah')),
            DataColumn(label: Text('Volume')),
            DataColumn(label: Text('Total Harga')),
          ],
          rows: penjualanDetail!['detail'].map<DataRow>((item) {
            // Handle konversi nilai jumlah_harga_jual dengan aman
            double jumlahHargaValue = 0.0;
            if (item['jumlah_harga_jual'] is double) {
              jumlahHargaValue = item['jumlah_harga_jual'];
            } else if (item['jumlah_harga_jual'] is int) {
              jumlahHargaValue = item['jumlah_harga_jual'].toDouble();
            } else if (item['jumlah_harga_jual'] is String) {
              jumlahHargaValue = _parseIndonesianNumber(
                item['jumlah_harga_jual'],
              );
            }

            return DataRow(
              cells: [
                DataCell(Text(item['kriteria'] ?? '-')),
                DataCell(Text(item['diameter'].toString())),
                DataCell(Text(item['panjang'].toString())),
                DataCell(Text(item['jumlah'].toString())),
                DataCell(Text(item['volume'].toString())),
                DataCell(
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(jumlahHargaValue),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ];
  }
}
