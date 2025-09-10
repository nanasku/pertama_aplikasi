import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sale_item.dart';

void main() {
  runApp(MaterialApp(home: TransaksiPenjualan()));
}

class TransaksiPenjualan extends StatefulWidget {
  @override
  _TransaksiPenjualanState createState() => _TransaksiPenjualanState();
}

class _TransaksiPenjualanState extends State<TransaksiPenjualan> {
  String? selectedCustomKriteria;
  bool modalVisible = false;
  String pembeli = '';
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
  String? latestItemId;

  List<Map<String, dynamic>> customVolumes = [];
  String customDiameter = '';
  String customVolumeValue = '';

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void handleAddOrUpdate() {
    if (diameter.isEmpty || panjang.isEmpty) return;

    double d = double.parse(diameter);
    double p = double.parse(panjang);

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

    var custom = customVolumes.firstWhere(
      (c) => c['diameter'] == d,
      orElse: () => {},
    );

    double volume;
    if (custom.isNotEmpty) {
      volume = custom['volume'].toDouble();
    } else {
      double rawVolume = (0.785 * d * d * p) / 1000;
      double decimal = rawVolume - rawVolume.floor();
      volume = (decimal >= 0.6 ? rawVolume.floor() + 1 : rawVolume.floor())
          .toDouble();
    }

    int hargaSatuan = int.tryParse(harga[currentKriteria] ?? '') ?? 0;
    int jumlahHarga = (volume * hargaSatuan).round();

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
        'jumlahHarga': volume * hargaSatuan * newJumlah,
      };
      updatedData = sortData(updatedData);
      setState(() {
        latestItemId = updatedData[existingIndex]['id'];
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
      });
    }

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
      appBar: AppBar(title: Text('Transaksi Penjualan')),
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
                    Text('Pembeli: $pembeli'),
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
              'Data Transaksi Penjualan:',
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
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Input tidak valid'),
                        content: Text(
                          'Diameter dan volume harus berupa angka yang valid.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Tambah Custom Volume'),
            ),
            SizedBox(height: 10),

            // Daftar Custom Volume
            if (customVolumes.isNotEmpty) ...[
              Text(
                'Daftar Custom Volume:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...customVolumes.map((item) {
                return Text('D ${item['diameter']} → V ${item['volume']}');
              }).toList(),
              SizedBox(height: 10),
            ],

            // Tombol Cetak
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Info'),
                      content: Text('Fungsi ekspor akan ditambahkan'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Cetak / Bagikan Invoice'),
            ),
            SizedBox(height: 20),

            // Footer
            Column(
              children: [
                Text(
                  '© 2025 - Transaksi Log Kayu',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Upgrade Aplikasi email ke h2duacahaya@gmail.com',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),

      // Modal Input Data
      bottomSheet: modalVisible ? _buildModal(context) : null,
    );
  }

  Widget _buildModal(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Input Data Penjualan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInputRow(
                    'Nama pembeli:',
                    pembeli,
                    (value) => setState(() => pembeli = value),
                  ),
                  _buildInputRow(
                    'Alamat pembeli:',
                    alamat,
                    (value) => setState(() => alamat = value),
                  ),
                  _buildInputRow(
                    'Nama Kayu:',
                    kayu,
                    (value) => setState(() => kayu = value),
                  ),
                  SizedBox(height: 10),
                  ...[
                    'Rijek 1',
                    'Rijek 2',
                    'Standar',
                    'Super A',
                    'Super B',
                    'Super C',
                  ].map((k) {
                    return _buildInputRow(
                      'Harga $k:',
                      harga[k] ?? '',
                      (value) => setState(() => harga[k] = value),
                      isNumeric: true,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                modalVisible = false;
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    String value,
    Function(String) onChanged, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label)),
          Expanded(
            flex: 6,
            child: TextField(
              keyboardType: isNumeric
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: isNumeric
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: onChanged,
              controller: TextEditingController(text: value),
            ),
          ),
        ],
      ),
    );
  }
}
