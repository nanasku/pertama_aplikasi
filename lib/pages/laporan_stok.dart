import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LaporanStokPage extends StatefulWidget {
  const LaporanStokPage({Key? key}) : super(key: key);

  @override
  State<LaporanStokPage> createState() => _LaporanStokPageState();
}

class _LaporanStokPageState extends State<LaporanStokPage> {
  String? _selectedNamaKayu;
  final Map<String, bool> _selectedKriteria = {
    'Rijek 1': false,
    'Rijek 2': false,
    'Standar': false,
    'Super A': false,
    'Super B': false,
    'Super C': false,
    'Rusak': false,
  };

  final List<String> namaKayuList = [
    'Kayu Alba',
    'Kayu Sengon',
    'Kayu Mahoni',
    'Kayu Balsa',
  ];

  List<StokData> stokList = [];
  bool isLoading = false;
  bool showStokOpnameModal = false;

  @override
  void initState() {
    super.initState();
    _loadNamaKayuList(); // Load daftar nama kayu dari API jika diperlukan
  }

  Future<void> _loadNamaKayuList() async {
    // Implementasi untuk mengambil daftar nama kayu dari API
    // Contoh:
    // final response = await http.get(Uri.parse('${dotenv.env['API_BASE_URL']}/nama-kayu'));
    // setState(() { namaKayuList = response.data; });
  }

  // Perbaikan pada _loadData() method
  Future<void> _loadData() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    final selectedKriteriaList = _selectedKriteria.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedKriteriaList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pilih minimal satu kriteria')));
      return;
    }

    setState(() {
      isLoading = true;
      stokList = []; // Reset data sebelumnya
    });

    try {
      // Encode nama kayu untuk URL
      final encodedNamaKayu = Uri.encodeComponent(_selectedNamaKayu!);

      // Debug: Print URL yang akan diakses
      final apiUrl =
          '${dotenv.env['API_BASE_URL']}/stok?nama_kayu=$encodedNamaKayu';
      print('API URL: $apiUrl');

      // Ambil data stok dari API
      final stokResponse = await http.get(Uri.parse(apiUrl));

      print('Response status: ${stokResponse.statusCode}');
      print('Response body: ${stokResponse.body}');

      if (stokResponse.statusCode == 200) {
        final List<dynamic> stokData = json.decode(stokResponse.body);

        print('Raw API data: $stokData');

        // Filter berdasarkan kriteria yang dipilih
        final filteredData = stokData
            .where((item) => selectedKriteriaList.contains(item['kriteria']))
            .toList();

        print('Filtered data: $filteredData');

        // Konversi ke List<StokData>
        final List<StokData> loadedData = filteredData
            .map(
              (item) => StokData(
                kriteria: item['kriteria']?.toString() ?? '',
                namaKayu: item['nama_kayu']?.toString() ?? '',
                diameter:
                    int.tryParse(item['diameter']?.toString() ?? '0') ?? 0,
                panjang: int.tryParse(item['panjang']?.toString() ?? '0') ?? 0,
                stokPembelian:
                    int.tryParse(item['stok_pembelian']?.toString() ?? '0') ??
                    0,
                stokPenjualan:
                    int.tryParse(item['stok_penjualan']?.toString() ?? '0') ??
                    0,
                stokRusak: 0, // Sesuaikan jika ada data rusak
                stokBuku:
                    int.tryParse(item['stok_buku']?.toString() ?? '0') ??
                    0, // << Tambah ini
              ),
            )
            .toList();

        setState(() {
          stokList = loadedData;
          isLoading = false;
        });

        print('Loaded ${loadedData.length} items');
      } else {
        throw Exception(
          'Failed to load stok data: ${stokResponse.statusCode} - ${stokResponse.body}',
        );
      }
    } catch (e) {
      print('Error details: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  List<StokData> _processApiData(dynamic pembelianData, dynamic penjualanData) {
    // Implementasi pengolahan data dari API
    // Ini adalah contoh - sesuaikan dengan struktur data API Anda
    List<StokData> result = [];

    // Logika pengolahan data disini
    return result;
  }

  Future<void> _loadStokOpname() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    setState(() {
      showStokOpnameModal = true;
    });

    // Implementasi untuk mengambil data stok opname dari API
    try {
      // final response = await http.get(
      //   Uri.parse('${dotenv.env['API_BASE_URL']}/stok-opname?nama_kayu=$_selectedNamaKayu'),
      // );
      // Proses data stok opname
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading stok opname: $e')));
    }
  }

  Future<void> _generatePDF() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    // Judul
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'LAPORAN STOK KAYU - $_selectedNamaKayu',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Kriteria terpilih
    final selectedKriteria = _selectedKriteria.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(', ');

    final PdfFont subTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    graphics.drawString(
      'Kriteria: $selectedKriteria',
      subTitleFont,
      bounds: Rect.fromLTWH(0, 50, page.getClientSize().width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Tanggal
    final PdfFont dateFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final String currentDate = DateFormat(
      'dd MMMM yyyy',
    ).format(DateTime.now());
    graphics.drawString(
      'Tanggal: $currentDate',
      dateFont,
      bounds: Rect.fromLTWH(0, 70, page.getClientSize().width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Tabel
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);

    // Header
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Kriteria';
    headerRow.cells[1].value = 'Diameter';
    headerRow.cells[2].value = 'Panjang';
    headerRow.cells[3].value = 'Stok Pembelian';
    headerRow.cells[4].value = 'Stok Terjual';
    headerRow.cells[5].value = 'Stok Rusak';
    headerRow.cells[6].value = 'Stok Akhir';

    // Data
    for (final stok in stokList) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = stok.kriteria;
      row.cells[1].value = stok.diameter.toString();
      row.cells[2].value = stok.panjang.toString();
      row.cells[3].value = stok.stokPembelian.toString();
      row.cells[4].value = stok.stokPenjualan.toString();
      row.cells[5].value = stok.stokRusak.toString();
      row.cells[6].value = stok.stokAkhir.toString();
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(20, 120, page.getClientSize().width - 40, 0),
    );

    // Simpan file
    final List<int> bytes = await document.save();
    document.dispose();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final File file = File(
      '$path/laporan_stok_${_selectedNamaKayu?.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    // Buka file
    OpenFile.open(file.path);
  }

  Future<void> _shareReport() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String fileName =
        'laporan_stok_${_selectedNamaKayu?.toLowerCase().replaceAll(' ', '_')}.pdf';
    final File file = File('$path/$fileName');

    if (!await file.exists()) {
      await _generatePDF();
    }

    final XFile xFile = XFile(file.path);
    await Share.shareXFiles([
      xFile,
    ], text: 'Laporan Stok Kayu - $_selectedNamaKayu');
  }

  void _showStokOpnameModal() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    try {
      // Ambil stok buku dari API
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL']}/stok/by-nama?nama_kayu=${Uri.encodeComponent(_selectedNamaKayu!)}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            // Buat controller untuk input opname
            final Map<String, TextEditingController> opnameControllers = {};

            return AlertDialog(
              title: Text('Stok Opname - $_selectedNamaKayu'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Kriteria')),
                        DataColumn(label: Text('Stok Buku')),
                        DataColumn(label: Text('Stok Opname')),
                        DataColumn(label: Text('Selisih')),
                      ],
                      rows: data.map((item) {
                        final kriteria = item['kriteria'].toString();
                        final stokBuku =
                            int.tryParse(item['stok_buku'].toString()) ?? 0;

                        // buat controller untuk input opname per kriteria
                        opnameControllers[kriteria] = TextEditingController();

                        return DataRow(
                          cells: [
                            DataCell(Text(kriteria)),
                            DataCell(Text(stokBuku.toString())),
                            DataCell(
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: opnameControllers[kriteria],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'SO',
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              ValueListenableBuilder(
                                valueListenable: opnameControllers[kriteria]!,
                                builder: (context, value, _) {
                                  final opname = int.tryParse(value.text) ?? 0;
                                  final selisih = opname - stokBuku;
                                  return Text(selisih.toString());
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Simpan semua opname ke backend
                    for (var item in data) {
                      final kriteria = item['kriteria'].toString();
                      final stokBuku =
                          int.tryParse(item['stok_buku'].toString()) ?? 0;
                      final opname =
                          int.tryParse(opnameControllers[kriteria]!.text) ?? 0;
                      final selisih = opname - stokBuku;

                      final opnameData = {
                        "nama_kayu": item['nama_kayu'],
                        "kriteria": kriteria,
                        "diameter": item['diameter'],
                        "panjang": item['panjang'],
                        "stok_opname": opname,
                        "tanggal_opname": DateFormat(
                          "yyyy-MM-dd",
                        ).format(DateTime.now()),
                        "keterangan": "Input via mobile",
                      };

                      await http.post(
                        Uri.parse('${dotenv.env['API_BASE_URL']}/stok/opname'),
                        headers: {"Content-Type": "application/json"},
                        body: json.encode(opnameData),
                      );
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stok opname berhasil disimpan'),
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception("Gagal ambil stok");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Stok Kayu'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Filter Nama Kayu dan Kriteria
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Pilih Nama Kayu:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedNamaKayu,
                      hint: Text('Pilih Kayu'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedNamaKayu = newValue;
                          // Reset kriteria ketika nama kayu berubah
                          _selectedKriteria.forEach((key, value) {
                            _selectedKriteria[key] = false;
                          });
                        });
                      },
                      items: namaKayuList.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Pilih Kriteria:'),
                Wrap(
                  spacing: 8,
                  children: _selectedKriteria.entries.map((entry) {
                    return FilterChip(
                      label: Text(entry.key),
                      selected: entry.value,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedKriteria[entry.key] = selected;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _loadData,
                      child: Text('Tampilkan Data'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _showStokOpnameModal,
                      child: Text('Stok Opname'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabel Data
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : stokList.isEmpty
                ? const Center(child: Text('Tidak ada data stok'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Kriteria')),
                        DataColumn(label: Text('Diameter (cm)')),
                        DataColumn(label: Text('Panjang (cm)')),
                        DataColumn(label: Text('Stok Pembelian')),
                        DataColumn(label: Text('Stok Penjualan')),
                        DataColumn(label: Text('Stok Rusak')),
                        DataColumn(label: Text('Stok Akhir')),
                      ],
                      rows: stokList.map((stok) {
                        return DataRow(
                          cells: [
                            DataCell(Text(stok.kriteria)),
                            DataCell(Text('${stok.diameter}')),
                            DataCell(Text('${stok.panjang}')),
                            DataCell(Text(stok.stokPembelian.toString())),
                            DataCell(Text(stok.stokPenjualan.toString())),
                            DataCell(Text(stok.stokRusak.toString())),
                            DataCell(
                              Text(
                                stok.stokAkhir.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: stok.stokAkhir < 10
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),

          // Tombol Aksi
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _generatePDF,
                  icon: const Icon(Icons.print),
                  label: const Text('Print PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _shareReport,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StokData {
  final String kriteria;
  final String namaKayu;
  final int diameter;
  final int panjang;
  final int stokPembelian;
  final int stokPenjualan;
  final int stokRusak;

  StokData({
    required this.kriteria,
    required this.namaKayu,
    required this.diameter,
    required this.panjang,
    required this.stokPembelian,
    required this.stokPenjualan,
    required this.stokRusak,
    required int stokBuku,
  });

  int get stokAkhir => stokPembelian - (stokPenjualan + stokRusak);
}
