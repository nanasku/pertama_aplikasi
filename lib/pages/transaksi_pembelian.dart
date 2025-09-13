import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(MaterialApp(home: TransaksiPembelian()));
}

class TransaksiPembelian extends StatefulWidget {
  @override
  _TransaksiPembelianState createState() => _TransaksiPembelianState();
}

class _TransaksiPembelianState extends State<TransaksiPembelian> {
  String? selectedCustomKriteria;
  bool modalVisible = false;
  String noFaktur = '';
  String penjual = '';
  String alamat = '';
  String kayu = '';

  Map<String, dynamic> harga = {
    'Rijek 1': 0.0,
    'Rijek 2': 0.0,
    'Standar': 0.0,
    'Super A': 0.0,
    'Super B': 0.0,
    'Super C': 0.0,
  };

  String kriteria = '';
  String diameter = '';
  String panjang = '';
  List<Map<String, dynamic>> data = [];
  Map<String, dynamic> pricesMap = {};
  String? latestItemId;

  List<Map<String, dynamic>> customVolumes = [];
  String customDiameter = '';
  String customVolumeValue = '';

  ScrollController _scrollController = ScrollController();

  // Data dari database
  List<Map<String, dynamic>> daftarPenjual = [];
  List<Map<String, dynamic>> daftarKayu = [];
  String? selectedPenjualId;
  String? selectedKayuId;
  String? selectedPenjualNama;
  String? selectedPenjualAlamat;
  String? selectedKayuNama;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateNoFaktur();
    _loadDataDariDatabase();
  }

  @override
  void dispose() {
    diameterController.dispose(); // ← ini ditambahkan auto focus
    panjangController.dispose(); // ← ini ditambahkan auto focus
    customDiameterController.dispose(); // ← ini ditambahkan auto focus
    customVolumeController.dispose(); // ← ini ditambahkan auto focus
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat data dari database
  Future<void> _loadDataDariDatabase() async {
    await _loadPenjual();
    await _loadKayu();
  }

  // Fungsi untuk memuat data penjual dari backend
  Future<void> _loadPenjual() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/penjual'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Loaded ${data.length} penjual');
        setState(() {
          daftarPenjual = data
              .map(
                (item) => {
                  'id': item['id'].toString(),
                  'nama': item['nama'],
                  'alamat': item['alamat'] ?? '',
                  'telepon': item['telepon'] ?? '',
                  'email': item['email'] ?? '',
                },
              )
              .toList();
        });
      }
    } catch (error) {
      print('Error loading penjual: $error');
    }
  }

  // Fungsi untuk memuat data kayu dari backend
  Future<void> _loadKayu() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/harga-beli'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Loaded ${data.length} kayu');
        setState(() {
          daftarKayu = data
              .map(
                (item) => {
                  'id': item['id'].toString(),
                  'nama_kayu': item['nama_kayu'],
                  'prices': item['prices'],
                },
              )
              .toList();
        });
      }
    } catch (error) {
      print('Error loading kayu: $error');
    }
  }

  void _generateNoFaktur() {
    DateTime now = DateTime.now();
    String datePart =
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
    // In a real app, you would get the next sequence number from the database
    String sequencePart = '0001';
    setState(() {
      noFaktur = 'PB-$datePart-$sequencePart';
    });
  }

  void handleAddOrUpdate() {
    if (diameter.isEmpty || panjang.isEmpty) return;

    double d = double.tryParse(diameter) ?? 0;
    double p = double.tryParse(panjang) ?? 0;
    if (d == 0 || p == 0) return;

    // 1. Tentukan kriteria berdasarkan diameter atau custom
    String currentKriteria = selectedCustomKriteria ?? '';
    if (currentKriteria.isEmpty) {
      if (d >= 10 && d <= 14) {
        currentKriteria = 'Rijek 1';
      } else if (d >= 15 && d <= 19) {
        currentKriteria = 'Rijek 2';
      } else if (d >= 20 && d <= 24) {
        currentKriteria = 'Standar';
      } else if (d >= 25) {
        currentKriteria = 'Super C';
      }
    }

    // Normalisasi label
    String normalizeKriteria(String label) {
      switch (label) {
        case 'R1':
          return 'Rijek 1';
        case 'R2':
          return 'Rijek 2';
        case 'St':
          return 'Standar';
        case 'Sp A':
          return 'Super A';
        case 'Sp B':
          return 'Super B';
        case 'Sp C':
          return 'Super C';
        default:
          return label;
      }
    }

    currentKriteria = normalizeKriteria(currentKriteria);

    print('Harga map: $harga');
    print('Current kriteria: $currentKriteria');

    // Ambil harga per satuan dengan handling tipe aman
    dynamic rawHarga = harga[currentKriteria];

    double hargaDouble = 0;

    if (rawHarga is String) {
      hargaDouble = double.tryParse(rawHarga) ?? 0;
    } else if (rawHarga is int) {
      hargaDouble = rawHarga.toDouble();
    } else if (rawHarga is double) {
      hargaDouble = rawHarga;
    } else {
      hargaDouble = 0;
    }

    int hargaSatuan = hargaDouble.round();
    if (hargaSatuan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga tidak ditemukan untuk grade $currentKriteria'),
        ),
      );
      return;
    }

    // 4. Hitung volume
    var custom = customVolumes.firstWhere(
      (c) => c['diameter'] == d,
      orElse: () => {},
    );

    double volume;
    if (custom.isNotEmpty) {
      var rawVol = custom['volume'];
      if (rawVol is int) {
        volume = rawVol.toDouble();
      } else if (rawVol is double) {
        volume = rawVol;
      } else if (rawVol is String) {
        volume = double.tryParse(rawVol) ?? 0;
      } else {
        volume = 0;
      }
    } else {
      double rawVolume = (0.785 * d * d * p) / 1000;
      double decimal = rawVolume - rawVolume.floor();
      volume = (decimal >= 0.6 ? rawVolume.floor() + 1 : rawVolume.floor())
          .toDouble();
    }

    // 5. Hitung total harga
    int jumlahHarga = (volume * hargaSatuan).round();

    // 6. Cek duplikasi
    int existingIndex = data.indexWhere(
      (item) =>
          item['diameter'] == d &&
          item['panjang'] == p &&
          item['kriteria'] == currentKriteria,
    );

    List<Map<String, dynamic>> updatedData;
    if (existingIndex >= 0) {
      updatedData = List<Map<String, dynamic>>.from(data);
      var item = updatedData[existingIndex];
      int newJumlah = item['jumlah'] + 1;
      updatedData[existingIndex] = {
        ...item,
        'jumlah': newJumlah,
        'jumlahHarga': (volume * hargaSatuan * newJumlah).round(),
      };
      updatedData = sortData(updatedData);
      setState(() {
        latestItemId = updatedData[existingIndex]['id'];
        data = updatedData;
      });
    } else {
      var newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'kriteria': currentKriteria,
        'diameter': d,
        'panjang': p,
        'jumlah': 1,
        'volume': volume,
        'harga': hargaSatuan,
        'jumlahHarga': jumlahHarga,
      };
      updatedData = sortData([...data, newItem]);
      setState(() {
        latestItemId = newItem['id'].toString();
        data = updatedData;
      });
    }

    // scroll ke bawah
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Map<String, dynamic>> sortData(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      if (a['kriteria'] != b['kriteria']) {
        return a['kriteria'].compareTo(b['kriteria']);
      }
      if (a['diameter'] != b['diameter']) {
        return a['diameter'].compareTo(b['diameter']);
      }
      return a['panjang'].compareTo(b['panjang']);
    });
    return list;
  }

  String getShortLabel(String kriteria) {
    switch (kriteria) {
      case 'Rijek 1':
        return 'R 1';
      case 'Rijek 2':
        return 'R 2';
      case 'Standar':
        return 'St';
      case 'Super A':
        return 'Sp A';
      case 'Super B':
        return 'Sp B';
      case 'Super C':
        return 'Sp C';
      default:
        return kriteria;
    }
  }

  void updateJumlah(String id, int delta) {
    setState(() {
      data = sortData(
        data.map((item) {
          if (item['id'] == id) {
            int jumlah = (item['jumlah'] + delta).clamp(1, 999999);
            return {
              ...item,
              'jumlah': jumlah,
              'jumlahHarga': item['volume'] * item['harga'] * jumlah,
            };
          }
          return item;
        }).toList(),
      );
    });
  }

  void handleDecrement(String id) {
    setState(() {
      int index = data.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        var item = data[index];
        if (item['jumlah'] <= 1) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Konfirmasi Hapus'),
                content: Text('Apakah Anda yakin ingin menghapus item ini?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        data.removeWhere((i) => i['id'] == id);
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        } else {
          item['jumlah'] -= 1;
          item['jumlahHarga'] = item['volume'] * item['jumlah'] * item['harga'];
          data = sortData(List.from(data));
        }
      }
    });
  }

  // Fungsi untuk menangani simpan transaksi
  Future<void> _handleSimpanTransaksi() async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada data transaksi untuk disimpan')),
      );
      return;
    }

    // Debug informasi
    print('selectedPenjualId: $selectedPenjualId');
    print('selectedKayuId: $selectedKayuId');
    print('penjual: $penjual');
    print('kayu: $kayu');

    if (selectedPenjualId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pilih penjual terlebih dahulu')));
      return;
    }

    if (selectedKayuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih jenis kayu terlebih dahulu')),
      );
      return;
    }

    // Tanyakan apakah mau dicetak
    bool? confirmPrint = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Transaksi pembelian Mau Dicetak?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    // Simpan ke database terlepas dari pilihan cetak
    await _simpanKeDatabase();

    // Jika memilih OK, maka cetak struk
    if (confirmPrint == true) {
      await _cetakStruk();
    }
  }

  // Fungsi untuk menyimpan ke database
  Future<void> _simpanKeDatabase() async {
    try {
      double totalHarga = data.fold(
        0,
        (sum, item) => sum + (item['jumlahHarga'] as double),
      );

      // Siapkan data items dengan format yang sesuai untuk backend
      List<Map<String, dynamic>> formattedItems = data.map((item) {
        return {
          'nama_kayu': kayu, // Nama kayu dari dropdown
          'kriteria': item['kriteria'] ?? '',
          'diameter': item['diameter'] ?? 0,
          'panjang': item['panjang'] ?? 0,
          'jumlah': item['jumlah'] ?? 0,
          'volume': item['volume'] ?? 0,
          'harga_beli': item['harga'] ?? 0, // Sesuai field di database
          'jumlah_harga_beli':
              item['jumlahHarga'] ?? 0, // Sesuai field di database
        };
      }).toList();

      print('Mengirim data ke server:');
      print('No Faktur: $noFaktur');
      print('Penjual ID: $selectedPenjualId');
      print('Product ID: $selectedKayuId');
      print('Total: $totalHarga');
      print('Items: $formattedItems');

      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/pembelian'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'no_faktur': noFaktur,
          'penjual_id': selectedPenjualId, // Sesuai dengan field di backend
          'product_id': selectedKayuId, // Sesuai dengan field di backend
          'total': totalHarga,
          'items': formattedItems,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transaksi berhasil disimpan')));

        // Reset data setelah berhasil disimpan
        setState(() {
          data = [];
          _generateNoFaktur(); // Generate nomor faktur baru
        });
      } else {
        throw Exception(
          'Gagal menyimpan transaksi. Status: ${response.statusCode}',
        );
      }
    } catch (error) {
      print('Error menyimpan transaksi: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Gagal menyimpan transaksi. Silakan coba lagi.'),
        ),
      );
    }
  }

  // Fungsi untuk mencetak struk (kompatibel dengan Printer POS)
  Future<void> _cetakStruk() async {
    // Hitung total
    double totalHarga = data.fold(
      0,
      (sum, item) => sum + (item['jumlahHarga'] as double),
    );
    double totalVolume = data.fold(
      0,
      (sum, item) => sum + (item['volume'] as double),
    );

    // Format struk untuk printer POS
    String struk =
        '''
    ================================
            TRANSAKSI PEMBELIAN
    ================================
    No Faktur: $noFaktur
    Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
    Penjual: $penjual
    Kayu: $kayu
    ================================
    ${data.map((item) => '${getShortLabel(item['kriteria'])} D${item['diameter']} P${item['panjang']} '
            'x${item['jumlah']} = ${item['volume']}m³\n'
            '@${item['harga']} = ${item['jumlahHarga']}').join('\n--------------------------------\n')}
    ================================
    Total Volume: ${totalVolume.toStringAsFixed(2)} m³
    Total Harga: Rp ${totalHarga.toStringAsFixed(0)}
    ================================
            TERIMA KASIH
    ================================
    ''';

    // Untuk mencetak ke printer POS, Anda perlu menggunakan package khusus
    // seperti esc_pos_printer atau flutter_blue_plus untuk Bluetooth printers
    print(struk); // Ini hanya contoh di console

    // Tampilkan preview struk
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Struk Pembelian'),
        content: SingleChildScrollView(
          child: Text(struk, style: TextStyle(fontFamily: 'Monospace')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk share PDF
  Future<void> _sharePDF() async {
    // Implementasi pembuatan PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur Share PDF akan segera hadir')),
    );
  }

  // Fungsi untuk share Excel
  Future<void> _shareExcel() async {
    // Implementasi pembuatan Excel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur Share Excel akan segera hadir')),
    );
  }

  TextEditingController diameterController = TextEditingController();
  TextEditingController panjangController = TextEditingController();
  TextEditingController customDiameterController = TextEditingController();
  TextEditingController customVolumeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaksi Pembelian')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            // Header dengan tombol Input Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      modalVisible = true;
                    });
                  },
                  child: Text('Input Data'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('No Faktur: $noFaktur'),
                    Text('Penjual: $penjual'),
                    Text('Nama Kayu: $kayu'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            // Custom Kriteria
            Text(
              'Custom Kriteria:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    {'short': 'St', 'full': 'Standar'},
                    {'short': 'Sp A', 'full': 'Super A'},
                    {'short': 'Sp B', 'full': 'Super B'},
                    {'short': 'Sp C', 'full': 'Super C'},
                  ].map((item) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCustomKriteria =
                              selectedCustomKriteria == item['full']
                              ? null
                              : item['full'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selectedCustomKriteria == item['full']
                              ? Colors.lightBlue
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item['short'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedCustomKriteria == item['full']
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 10),

            // Input Panjang dan Diameter
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panjang:'),
                      TextField(
                        controller: panjangController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Panjang',
                        ),
                        onChanged: (value) => setState(() => panjang = value),
                        onTap: () {
                          // Blok semua teks saat TextField diklik
                          panjangController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: panjangController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diameter:'),
                      TextField(
                        controller: diameterController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Diameter',
                        ),
                        onChanged: (value) => setState(() => diameter = value),
                        onTap: () {
                          // Blok semua teks saat TextField diklik
                          diameterController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: diameterController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Tombol OK
            ElevatedButton(onPressed: handleAddOrUpdate, child: Text('OK')),
            SizedBox(height: 10),

            // Tabel Data Transaksi
            Text(
              'Data Transaksi Pembelian:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Header Tabel
            Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
                7: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Grade',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'D',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'P',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Jml',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Vol',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Hrg',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Aksi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Isi Tabel dengan Scroll
            Container(
              height: 250,
              child: Scrollbar(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    var item = data[index];
                    return Container(
                      color: item['id'] == latestItemId
                          ? Color(0xFFd0f0c0)
                          : Colors.white,
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1),
                          6: FlexColumnWidth(1),
                          7: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(
                                      getShortLabel(item['kriteria']),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['diameter'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['panjang'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['jumlah'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['volume'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['harga'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['jumlahHarga'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // <<< tambahkan ini
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () =>
                                          handleDecrement(item['id']),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () =>
                                          updateJumlah(item['id'], 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),

            // Custom Volume
            Text(
              'Custom Volume (Opsional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diameter:'),
                      TextField(
                        controller: customDiameterController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Diameter',
                        ),
                        onChanged: (value) =>
                            setState(() => customDiameter = value),
                        onTap: () {
                          // Blok semua teks saat TextField diklik
                          customDiameterController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: customDiameterController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Volume:'),
                      TextField(
                        controller: customVolumeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Volume',
                        ),
                        onChanged: (value) =>
                            setState(() => customVolumeValue = value),
                        onTap: () {
                          // Blok semua teks saat TextField diklik
                          customVolumeController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: customVolumeController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                double d = double.tryParse(customDiameter) ?? 0;
                int v = int.tryParse(customVolumeValue) ?? 0;
                if (d > 0 && v > 0) {
                  setState(() {
                    customVolumes.removeWhere((c) => c['diameter'] == d);
                    customVolumes.add({'diameter': d, 'volume': v});
                    customDiameter = '';
                    customVolumeValue = '';
                  });
                }
              },
              child: Text('Tambah Custom Volume'),
            ),
            SizedBox(height: 10),
            Text('Daftar Custom Volume:'),
            ...customVolumes.map((c) {
              return Row(
                children: [
                  Text('Diameter ${c['diameter']}: Volume ${c['volume']}'),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        customVolumes.removeWhere(
                          (item) => item['diameter'] == c['diameter'],
                        );
                      });
                    },
                  ),
                ],
              );
            }).toList(),

            // Tambahkan di bagian bawah setelah Daftar Custom Volume
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleSimpanTransaksi(),
                  child: Text('Simpan/Cetak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _sharePDF(),
                  child: Text('Share PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _shareExcel(),
                  child: Text('Share Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Modal Input Data Pembelian - DIPERBAIKI
      floatingActionButton: modalVisible
          ? Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Data Pembelian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text('No Faktur: $noFaktur'),
                  SizedBox(height: 10),

                  // Dropdown untuk memilih Penjual
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Pilih Penjual',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedPenjualId,
                    items: daftarPenjual.map<DropdownMenuItem<String>>((
                      penjual,
                    ) {
                      final idStr = penjual['id']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: idStr,
                        child: Text(penjual['nama']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedPenjualId = value;
                        final selected = daftarPenjual.firstWhere(
                          (p) => p['id']?.toString() == value,
                          orElse: () => <String, dynamic>{},
                        );
                        if (selected.isNotEmpty) {
                          selectedPenjualNama = selected['nama']?.toString();
                          selectedPenjualAlamat = selected['alamat']
                              ?.toString();
                          penjual = selectedPenjualNama ?? '';
                          alamat = selectedPenjualAlamat ?? '';
                        }
                      });
                    },
                  ),

                  SizedBox(height: 10),
                  Text('Alamat: ${selectedPenjualAlamat ?? ''}'),
                  SizedBox(height: 10),

                  // Dropdown untuk memilih Kayu
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Pilih Jenis Kayu',
                      border: OutlineInputBorder(),
                    ),
                    value:
                        daftarKayu.any(
                          (k) => k['id'].toString() == selectedKayuId,
                        )
                        ? selectedKayuId
                        : null,
                    items: daftarKayu.map<DropdownMenuItem<String>>((kayu) {
                      final idStr = kayu['id']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: idStr,
                        child: Text(kayu['nama_kayu']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedKayuId = value;
                        final selected = daftarKayu.firstWhere(
                          (k) => k['id']?.toString() == value,
                          orElse: () => <String, dynamic>{},
                        );

                        if (selected.isNotEmpty) {
                          selectedKayuNama = selected['nama_kayu']?.toString();
                          kayu = selectedKayuNama ?? '';

                          if (selected['prices'] is Map) {
                            final pricesMap = Map<String, dynamic>.from(
                              selected['prices'],
                            );
                            harga = pricesMap.map(
                              (k, v) => MapEntry(k.toString(), v.toString()),
                            );
                          } else {
                            // PERBAIKAN: Gunakan nilai default jika prices tidak valid
                            harga = {
                              'Rijek 1': '0',
                              'Rijek 2': '0',
                              'Standar': '0',
                              'Super A': '0',
                              'Super B': '0',
                              'Super C': '0',
                            };
                          }

                          // Debug: Print untuk memastikan harga ter-set dengan benar
                          print('Harga setelah pemilihan kayu: $harga');
                        }
                      });
                    },
                  ),

                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            print(
                              'Modal Simpan ditekan - selectedPenjualId: $selectedPenjualId, selectedKayuId: $selectedKayuId',
                            );

                            if (selectedPenjualId != null &&
                                selectedKayuId != null) {
                              setState(() {
                                modalVisible = false;
                                // JANGAN reset selectedKayuId di sini!
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pilih penjual dan jenis kayu terlebih dahulu',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text('Simpan'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              modalVisible = false;
                              // JANGAN reset selectedKayuId di sini!
                            });
                          },
                          child: Text('Batal'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
