import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Map<String, String> harga = {
    'Rijek 1': '',
    'Rijek 2': '',
    'Standar': '',
    'Super A': '',
    'Super B': '',
    'Super C': '',
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

    // 1. Tentukan kriteria berdasarkan custom atau diameter
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

    // 2. Normalisasi label ke format map harga
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

    // 3. Ambil harga dari map berdasarkan kriteria
    int hargaSatuan = ((harga[currentKriteria] ?? 0) as double).round();
    if (hargaSatuan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga tidak ditemukan untuk grade $currentKriteria'),
        ),
      );
      return;
    }

    // 4. Hitung volume (cek custom volume dulu)
    var custom = customVolumes.firstWhere(
      (c) => c['diameter'] == d,
      orElse: () => {},
    );

    double volume;
    if (custom.isNotEmpty) {
      volume = (custom['volume'] ?? 0).toDouble();
    } else {
      double rawVolume = (0.785 * d * d * p) / 1000;
      double decimal = rawVolume - rawVolume.floor();
      print(
        'custom volume: ${custom['volume']} (type: ${custom['volume']?.runtimeType})',
      );
      volume = (decimal >= 0.6 ? rawVolume.floor() + 1 : rawVolume.floor())
          .toDouble();
    }

    // 5. Hitung total harga
    int jumlahHarga = (volume * hargaSatuan).round();

    // 6. Cek apakah item ini sudah ada
    int existingIndex = data.indexWhere(
      (item) =>
          item['diameter'] == d &&
          item['panjang'] == p &&
          item['kriteria'] == currentKriteria,
    );

    List<Map<String, dynamic>> updatedData;
    if (existingIndex >= 0) {
      // Update jumlah dan total
      updatedData = List<Map<String, dynamic>>.from(data);
      var item = updatedData[existingIndex];
      int newJumlah = item['jumlah'] + 1;
      updatedData[existingIndex] = {
        ...item,
        'jumlah': newJumlah,
        'jumlahHarga': volume * hargaSatuan * newJumlah,
      };
      updatedData = sortData(updatedData);
      setState(() {
        latestItemId = updatedData[existingIndex]['id'];
      });
    } else {
      // Tambah item baru
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
      });
    }

    // 7. Update state data dan scroll ke bawah
    setState(() {
      data = updatedData;
    });

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
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Panjang',
                        ),
                        onChanged: (value) => setState(() => panjang = value),
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
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Diameter',
                        ),
                        onChanged: (value) => setState(() => diameter = value),
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
                    isExpanded: true, // biar teks tidak terpotong
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
                            harga = {
                              'Rijek 1':
                                  pricesMap['Rijek 1']?.toString() ?? '0',
                              'Rijek 2':
                                  pricesMap['Rijek 2']?.toString() ?? '0',
                              'Standar':
                                  pricesMap['Standar']?.toString() ?? '0',
                              'Super A':
                                  pricesMap['Super A']?.toString() ?? '0',
                              'Super B':
                                  pricesMap['Super B']?.toString() ?? '0',
                              'Super C':
                                  pricesMap['Super C']?.toString() ?? '0',
                            };
                          }
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
                            if (selectedPenjualId != null &&
                                selectedKayuId != null) {
                              setState(() {
                                modalVisible = false;
                                selectedKayuId = null;
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
                              selectedKayuId = null;
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
