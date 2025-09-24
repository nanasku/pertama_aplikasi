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
  final Map<String, TextEditingController> opnameControllers = {};
  final Map<String, TextEditingController> rusakControllers = {};

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

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

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
          '${dotenv.env['API_BASE_URL']}/stok/laporan?tahun=$_selectedYear&bulan=$_selectedMonth&nama_kayu=$encodedNamaKayu';

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
                kriteria: item['kriteria'] ?? '',
                namaKayu: item['nama_kayu'] ?? '',
                diameter: int.tryParse(item['diameter'].toString()) ?? 0,
                panjang: int.tryParse(item['panjang'].toString()) ?? 0,
                stokAwal: int.tryParse(item['stok_awal'].toString()) ?? 0,
                stokPembelian:
                    int.tryParse(item['stok_pembelian'].toString()) ?? 0,
                stokPenjualan:
                    int.tryParse(item['stok_penjualan'].toString()) ?? 0,
                stokRusak: 0, // nanti kalau ada tabel rusak bisa ditambah
                stokAkhir: int.tryParse(item['stok_akhir'].toString()) ?? 0,
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

    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'LAPORAN STOK KAYU - $_selectedNamaKayu',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Kriteria';
    headerRow.cells[1].value = 'Diameter';
    headerRow.cells[2].value = 'Panjang';
    headerRow.cells[3].value = 'Stok Pembelian';
    headerRow.cells[4].value = 'Stok Terjual';
    headerRow.cells[5].value = 'Stok Rusak';
    headerRow.cells[6].value = 'Stok Akhir';

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

    final List<int> bytes = await document.save();
    document.dispose();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}/laporan_stok_${_selectedNamaKayu?.toLowerCase().replaceAll(' ', '_')}.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // 🔔 otomatis buka PDF setelah tersimpan
    await OpenFile.open(file.path);
  }

  Future<void> _shareWhatsApp() async {
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

  Future<void> _generateStokOpnamePDF(List<dynamic> data) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'LAPORAN STOK OPNAME - $_selectedNamaKayu',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Kriteria';
    headerRow.cells[1].value = 'Diameter';
    headerRow.cells[2].value = 'Panjang';
    headerRow.cells[3].value = 'Stok Buku';
    headerRow.cells[4].value = 'Opname';
    headerRow.cells[5].value = 'Rusak';
    headerRow.cells[6].value = 'Selisih';

    for (var item in data) {
      final kriteria = item['kriteria'].toString();
      final diameter = item['diameter'].toString();
      final panjang = item['panjang'].toString();
      final stokBuku = int.tryParse(item['stok_buku'].toString()) ?? 0;

      final uniqueKey = '$kriteria-$diameter-$panjang';
      final opname =
          int.tryParse(opnameControllers[uniqueKey]?.text ?? '') ?? 0;
      final rusak = int.tryParse(rusakControllers[uniqueKey]?.text ?? '') ?? 0;
      final selisih = opname + rusak - stokBuku;

      final row = grid.rows.add();
      row.cells[0].value = kriteria;
      row.cells[1].value = diameter;
      row.cells[2].value = panjang;
      row.cells[3].value = stokBuku.toString();
      row.cells[4].value = opname.toString();
      row.cells[5].value = rusak.toString();
      row.cells[6].value = selisih.toString();
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(20, 100, page.getClientSize().width - 40, 0),
    );

    final List<int> bytes = await document.save();
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/stok_opname_${_selectedNamaKayu!.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    // Share via WhatsApp
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Laporan Stok Opname - $_selectedNamaKayu');
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
            final Map<String, TextEditingController> rusakControllers = {};

            return AlertDialog(
              title: Text('Stok Opname - $_selectedNamaKayu'),
              content: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Grade')),
                          DataColumn(label: Text('D')),
                          DataColumn(label: Text('P')),
                          DataColumn(label: Text('Buku')),
                          DataColumn(label: Text('SO')),
                          DataColumn(label: Text('Rusak')),
                          DataColumn(label: Text('Selisih')),
                        ],
                        rows: data.map((item) {
                          final kriteria = item['kriteria'].toString();
                          final diameter = item['diameter'].toString();
                          final panjang = item['panjang'].toString();
                          final stokBuku =
                              int.tryParse(item['stok_buku'].toString()) ?? 0;

                          final uniqueKey =
                              '$kriteria-$diameter-$panjang'; // supaya unik

                          opnameControllers[uniqueKey] =
                              TextEditingController();
                          rusakControllers[uniqueKey] = TextEditingController();

                          return DataRow(
                            cells: [
                              DataCell(Text(kriteria)),
                              DataCell(Text(diameter)),
                              DataCell(Text(panjang)),
                              DataCell(Text(stokBuku.toString())),
                              DataCell(
                                SizedBox(
                                  width: 20,
                                  child: TextField(
                                    controller: opnameControllers[uniqueKey],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 20,
                                  child: TextField(
                                    controller: rusakControllers[uniqueKey],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                ValueListenableBuilder(
                                  valueListenable:
                                      opnameControllers[uniqueKey]!,
                                  builder: (context, opnameValue, _) {
                                    final opname =
                                        int.tryParse(opnameValue.text) ?? 0;
                                    final rusak =
                                        int.tryParse(
                                          rusakControllers[uniqueKey]?.text ??
                                              '',
                                        ) ??
                                        0;
                                    final selisih = opname + rusak - stokBuku;
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
              ),

              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 209, 188, 1),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    for (var item in data) {
                      final kriteria = item['kriteria'].toString();
                      final diameter = item['diameter'].toString();
                      final panjang = item['panjang'].toString();
                      final stokBuku =
                          int.tryParse(item['stok_buku'].toString()) ?? 0;

                      final uniqueKey = '$kriteria-$diameter-$panjang';

                      final opname =
                          int.tryParse(
                            opnameControllers[uniqueKey]?.text ?? '',
                          ) ??
                          0;
                      final rusak =
                          int.tryParse(
                            rusakControllers[uniqueKey]?.text ?? '',
                          ) ??
                          0;

                      if (opname + rusak > stokBuku) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Jumlah SO (${opname}) + Rusak (${rusak}) tidak boleh melebihi Stok Buku (${stokBuku}) untuk $kriteria ($diameter x $panjang)',
                            ),
                          ),
                        );
                        return; // ❗ Stop proses simpan jika salah satu data tidak valid
                      }

                      final opnameData = {
                        "nama_kayu": item['nama_kayu'],
                        "kriteria": kriteria,
                        "diameter": item['diameter'],
                        "panjang": item['panjang'],
                        "stok_opname": opname,
                        "stok_rusak": rusak,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _generateStokOpnamePDF(data);
                  },
                  child: const Text('Share WA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
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
                    // Pilih Tahun
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    // Pilih Bulan
                    DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                            DateFormat.MMMM().format(DateTime(0, month)),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        }
                      },
                    ),
                  ],
                ),

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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Grade')),
                          DataColumn(label: Text('D (cm)')),
                          DataColumn(label: Text('P (cm)')),
                          DataColumn(label: Text('Stok Beli')),
                          DataColumn(label: Text('Stok Jual')),
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
                  onPressed: _shareWhatsApp,
                  icon: const Icon(Icons.share),
                  label: const Text('Share WhatsApp'),
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
  final int stokAwal; // 🆕 stok awal
  final int stokPembelian;
  final int stokPenjualan;
  final int stokRusak;
  final int stokAkhir; // 🆕 stok akhir dari backend

  StokData({
    required this.kriteria,
    required this.namaKayu,
    required this.diameter,
    required this.panjang,
    required this.stokAwal,
    required this.stokPembelian,
    required this.stokPenjualan,
    required this.stokRusak,
    required this.stokAkhir,
  });
}
