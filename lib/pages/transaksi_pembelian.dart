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
  const TransaksiPembelian({super.key});

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

  // Variabel untuk operasional
  List<Map<String, dynamic>> operasionals = [];
  TextEditingController operasionalJenisController = TextEditingController();
  TextEditingController operasionalBiayaController = TextEditingController();
  String operasionalTipe = 'tambah'; // 'tambah' atau 'kurang'

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    getNoFakturBaru();
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

  void resetForm() {
    setState(() {
      panjangController.clear();
      diameterController.clear();
      customDiameterController.clear();
      customVolumeController.clear();

      selectedCustomKriteria = null;
      selectedPenjualId = null;
      selectedPenjualNama = null;
      selectedPenjualAlamat = null;
      selectedKayuId = null;
      selectedKayuNama = null;

      penjual = ''; // reset teks penjual
      alamat = ''; // reset alamat
      kayu = ''; // reset nama kayu

      data.clear(); // kosongkan tabel detail
    });

    // generate faktur baru lagi
    getNoFakturBaru();
  }

  double get totalVolume {
    return data.fold(0, (sum, item) => sum + (item['volume'] * item['jumlah']));
  }

  double get totalHarga {
    return data.fold(0, (sum, item) => sum + item['jumlahHarga']);
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

  Future<void> getNoFakturBaru() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/pembelian/noFakturBaru'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          noFaktur = data['faktur_pemb']; // <-- isi ke state
        });
      } else {
        print("Gagal ambil no faktur: ${response.body}");
      }
    } catch (e) {
      print("Error fetch noFakturBaru: $e");
    }
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
    // Simpan ke database
    await _simpanKeDatabase();
    // Jika memilih cetak
    if (confirmPrint == true) {
      await _cetakStruk();
    }
    // Baru reset form setelah cetak
    resetForm();
  }

  // Fungsi untuk menyimpan ke database
  Future<void> _simpanKeDatabase() async {
    try {
      double totalHarga = data.fold(
        0,
        (sum, item) => sum + (item['jumlahHarga'] as double),
      );

      // Hitung total operasional
      double totalOperasional = 0;
      for (var op in operasionals) {
        if (op['tipe'] == 'tambah') {
          totalOperasional += op['biaya'];
        } else {
          totalOperasional -= op['biaya'];
        }
      }

      double totalAkhir = totalHarga + totalOperasional;

      // Siapkan data items dengan format yang sesuai untuk backend
      List<Map<String, dynamic>> formattedItems = data.map((item) {
        return {
          'nama_kayu': kayu,
          'kriteria': item['kriteria'] ?? '',
          'diameter': item['diameter'] ?? 0,
          'panjang': item['panjang'] ?? 0,
          'jumlah': item['jumlah'] ?? 0,
          'volume': item['volume'] ?? 0,
          'harga_beli': item['harga'] ?? 0,
          'jumlah_harga_beli': item['jumlahHarga'] ?? 0,
        };
      }).toList();

      // Siapkan data operasional
      List<Map<String, dynamic>> formattedOperasionals = operasionals.map((op) {
        return {'jenis': op['jenis'], 'biaya': op['biaya'], 'tipe': op['tipe']};
      }).toList();

      print('Mengirim data ke server:');
      print('No Faktur: $noFaktur');
      print('Penjual ID: $selectedPenjualId');
      print('Product ID: $selectedKayuId');
      print('Total: $totalAkhir');
      print('Items: $formattedItems');
      print('Operasionals: $formattedOperasionals');

      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/pembelian'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'no_faktur': noFaktur,
          'penjual_id': selectedPenjualId,
          'product_id': selectedKayuId,
          'total': totalAkhir,
          'items': formattedItems,
          'operasionals': formattedOperasionals,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transaksi berhasil disimpan')));
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

  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '', // kosongkan jika tidak mau "Rp"
    decimalDigits: 0, // Tidak pakai desimal
  );

  String formatItem(item) {
    // Baris 1: Identitas barang
    String kriteria = getShortLabel(
      item['kriteria'],
    ).padRight(3); // e.g., 'R 1'
    String diameter = 'D${item['diameter']}'.padRight(4); // e.g., 'D10'
    String panjang = 'P${item['panjang']}'.padRight(5); // e.g., 'P130'
    String jumlah = '@${item['jumlah']}'; // e.g., '@8'

    String line1 = '$kriteria $diameter $panjang $jumlah';

    // Baris 2: Kalkulasi — rata kanan
    String volume = '${item['volume'].toStringAsFixed(0)}cm³';
    String harga = formatter.format(item['harga']);
    String jumlahHarga = formatter.format(item['jumlahHarga']);

    // Misalnya hasil: (23cm³ x 1.500) = 172.500
    String calc = '($volume x $harga) = $jumlahHarga';

    // Sesuaikan panjang maksimum baris struk (umumnya 42 karakter untuk printer POS)
    String line2 = calc.padLeft(42);

    return '$line1\n$line2';
  }

  String formatBaris(String label, String value, {int width = 16}) {
    return label.padRight(width) + ': ' + value;
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
      (sum, item) =>
          sum + ((item['volume'] as double) * (item['jumlah'] as int)),
    );

    // Hitung total operasional
    double totalOperasional = 0;
    String operasionalDetail = '';
    for (var op in operasionals) {
      String tipe = op['tipe'] == 'tambah' ? '+' : '-';
      operasionalDetail +=
          '${tipe} ${op['jenis']}: ${formatter.format(op['biaya'])}\n';
      if (op['tipe'] == 'tambah') {
        totalOperasional += op['biaya'];
      } else {
        totalOperasional -= op['biaya'];
      }
    }

    double totalAkhir = totalHarga + totalOperasional;

    // Format struk untuk printer POS
    String struk =
        '''
    ========================================
              TRANSAKSI PEMBELIAN
    ========================================
    ${formatBaris('No Faktur', noFaktur)}
    ${formatBaris('Tanggal', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()))}
    ${formatBaris('Penjual', penjual)}
    ${formatBaris('Kayu', kayu)}
    ========================================
    ${data.map((item) => formatItem(item)).join('\n--------------------------------\n')}
    ========================================
    Total Volume     : ${totalVolume.toStringAsFixed(2).padLeft(10)} cm³
    Total Harga      : ${formatter.format(totalHarga).padLeft(10)}
    Total Operasional: ${formatter.format(totalOperasional).padLeft(10)}
    TOTAL AKHIR      : ${formatter.format(totalAkhir).padLeft(10)}
    ========================================
                  TERIMA KASIH
    ========================================
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

  // === Ambil transaksi terakhir hari ini dari backend ===
  Future _getLastTransactionToday() async {
    try {
      final today = DateFormat('ddMMyyyy').format(DateTime.now());

      final response = await http.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL']}/pembelian?today=$today&last=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first;
        }
        if (data is Map) {
          return data;
        }
      }
    } catch (e) {
      print("Error fetch last transaction: $e");
    }
    return null;
  }

  // === SHARE PDF ===
  Future<void> _sharePDF() async {
    final trx = await _getLastTransactionToday();
    if (trx == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak ada transaksi hari ini')));
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Struk Pembelian', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('No Faktur: ${trx['faktur_pemb']}'),
              pw.Text('Tanggal : ${trx['created_at']}'),
              pw.Text('Penjual : ${trx['nama_penjual'] ?? ''}'),
              pw.Text('Kayu    : ${trx['nama_barang'] ?? ''}'),
              pw.Divider(),
              pw.Text('Detail Pembelian:'),
              if (trx['detail'] != null && trx['detail'] is List)
                ...trx['detail'].map<pw.Widget>((item) {
                  return pw.Text(
                    '${item['kriteria']} D${item['diameter']} '
                    'P${item['panjang']} x${item['jumlah']} '
                    '= ${item['jumlah_harga_beli']}',
                  );
                }),
              pw.Divider(),
              pw.Text('Total: ${trx['total']}'),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/transaksi_${trx['faktur_pemb']}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Transaksi Pembelian ${trx['faktur_pemb']}');
  }

  // === SHARE EXCEL ===
  Future<void> _shareExcel() async {
    final trx = await _getLastTransactionToday();
    if (trx == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak ada transaksi hari ini')));
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Pembelian'];

    // Header utama
    sheet.appendRow(['No Faktur', trx['faktur_pemb']]);
    sheet.appendRow(['Tanggal', trx['created_at']]);
    sheet.appendRow(['Penjual', trx['nama_penjual'] ?? '']);
    sheet.appendRow(['Kayu', trx['nama_barang'] ?? '']);
    sheet.appendRow([]);
    sheet.appendRow([
      'Kriteria',
      'Diameter',
      'Panjang',
      'Jumlah',
      'Volume',
      'Harga',
      'Total',
    ]);

    // Detail transaksi
    if (trx['detail'] != null && trx['detail'] is List) {
      for (var item in trx['detail']) {
        sheet.appendRow([
          item['kriteria'],
          item['diameter'],
          item['panjang'],
          item['jumlah'],
          item['volume'],
          item['harga_beli'],
          item['jumlah_harga_beli'],
        ]);
      }
    } else {
      sheet.appendRow(['Tidak ada detail transaksi']);
    }

    // Total akhir
    sheet.appendRow([]);
    sheet.appendRow(['Total', trx['total']]);

    // Simpan file Excel ke direktori temporary
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/transaksi_${trx['faktur_pemb']}.xlsx');
    await file.writeAsBytes(excel.encode()!);

    // Share via WhatsApp (atau aplikasi lain di Android/iOS)
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Excel Transaksi ${trx['faktur_pemb']}');
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
            SizedBox(
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
            }),

            // Tambahkan di bagian bawah setelah Daftar Custom Volume
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleSimpanTransaksi(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Simpan/Cetak'),
                ),
                ElevatedButton(
                  onPressed: () => _sharePDF(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Share PDF'),
                ),
                ElevatedButton(
                  onPressed: () => _shareExcel(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Share Excel'),
                ),
              ],
            ),
          ],
        ),
      ),

      // Modal Input Data Pembelian
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Data Pembelian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      initialValue: selectedPenjualId,
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
                      initialValue:
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
                            selectedKayuNama = selected['nama_kayu']
                                ?.toString();
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

                    // TAMBAHAN: Field Operasional
                    SizedBox(height: 20),
                    Text(
                      'Biaya Operasional:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Daftar operasional yang sudah ditambahkan
                    ...operasionals.map((op) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jenis: ${op['jenis']}'),
                                    Text(
                                      'Biaya: ${formatter.format(op['biaya'])}',
                                    ),
                                    Text(
                                      'Tipe: ${op['tipe'] == 'tambah' ? 'Menambah' : 'Mengurangi'}',
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    operasionals.removeWhere(
                                      (item) => item['id'] == op['id'],
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // Form untuk menambah operasional baru
                    SizedBox(height: 10),
                    TextField(
                      controller: operasionalJenisController,
                      decoration: InputDecoration(
                        labelText: 'Jenis Operasional',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: operasionalBiayaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Biaya (Rp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Tipe:'),
                        SizedBox(width: 10),
                        ChoiceChip(
                          label: Text('Menambah'),
                          selected: operasionalTipe == 'tambah',
                          onSelected: (selected) {
                            setState(() {
                              operasionalTipe = selected ? 'tambah' : 'kurang';
                            });
                          },
                        ),
                        SizedBox(width: 10),
                        ChoiceChip(
                          label: Text('Mengurangi'),
                          selected: operasionalTipe == 'kurang',
                          onSelected: (selected) {
                            setState(() {
                              operasionalTipe = selected ? 'kurang' : 'tambah';
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final jenis = operasionalJenisController.text.trim();
                        final biaya =
                            int.tryParse(operasionalBiayaController.text) ?? 0;

                        if (jenis.isNotEmpty && biaya > 0) {
                          setState(() {
                            operasionals.add({
                              'id': DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              'jenis': jenis,
                              'biaya': biaya,
                              'tipe': operasionalTipe,
                            });
                            operasionalJenisController.clear();
                            operasionalBiayaController.clear();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Isi jenis dan biaya dengan benar'),
                            ),
                          );
                        }
                      },
                      child: Text('+ Tambah Operasional'),
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
              ),
            )
          : null,
    );
  }
}
