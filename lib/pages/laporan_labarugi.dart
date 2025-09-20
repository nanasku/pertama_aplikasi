import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class LaporanLabaRugiPage extends StatefulWidget {
  @override
  _LaporanLabaRugiPageState createState() => _LaporanLabaRugiPageState();
}

class _LaporanLabaRugiPageState extends State<LaporanLabaRugiPage> {
  double totalPembelian = 0;
  double totalPenjualan = 0;
  double totalOperasional = 0;

  bool isLoading = true;
  String errorMessage = '';

  int _selectedFilterIndex = 0; // 0: Harian, 1: Bulanan, 2: Tahunan
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  DateTime? _selectedYear;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    fetchLabaRugi();
  }

  Future<void> fetchLabaRugi() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String param;

      if (_selectedFilterIndex == 0 && _selectedDate != null) {
        // Mode Harian
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        param = '?tanggal=$formattedDate';
      } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
        // Mode Bulanan
        final formattedMonth = DateFormat('yyyy-MM').format(_selectedMonth!);
        param = '?bulan=$formattedMonth';
      } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
        // Mode Tahunan
        param = '?tahun=${_selectedYear!.year}';
      } else {
        // Default: hari ini
        final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        param = '?tanggal=$formattedDate';
      }

      final pembelianRes = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/pembelian$param'),
      );
      final penjualanRes = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/penjualan$param'),
      );

      if (pembelianRes.statusCode == 200 && penjualanRes.statusCode == 200) {
        final pembelianData = json.decode(pembelianRes.body);
        final penjualanData = json.decode(penjualanRes.body);

        double pembelian = 0;
        double operasional = 0;
        for (var item in pembelianData) {
          pembelian += (item['total'] ?? 0) * 1.0;

          final ops = item['operasionals'] ?? [];
          for (var op in ops) {
            operasional += (op['biaya'] ?? 0) * 1.0;
          }
        }

        double penjualan = 0;
        for (var item in penjualanData) {
          penjualan += (item['total'] ?? 0) * 1.0;
        }

        setState(() {
          totalPembelian = pembelian;
          totalPenjualan = penjualan;
          totalOperasional = operasional;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data dari server';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      fetchLabaRugi();
    }
  }

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
      fetchLabaRugi();
    }
  }

  void _pickYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedYear ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked;
      });
      fetchLabaRugi();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedMonth = null;
      _selectedYear = null;
    });
    fetchLabaRugi();
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
            });
            fetchLabaRugi();
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
    if (_selectedFilterIndex == 0) {
      // Harian
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                        : 'Pilih Tanggal',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_selectedFilterIndex == 1) {
      // Bulanan
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pickMonth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedMonth != null
                        ? DateFormat('MMMM yyyy').format(_selectedMonth!)
                        : 'Pilih Bulan',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Tahunan
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pickYear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedYear != null
                        ? DateFormat('yyyy').format(_selectedYear!)
                        : 'Pilih Tahun',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  // Fungsi-fungsi onPrint, onSharePDF, onSendWhatsApp tetap sama...
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  void onPrint() async {
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected != true) {
        final devices = await bluetooth.getBondedDevices();
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tidak ada printer POS terpasang")),
          );
          return;
        }

        bluetooth.connect(devices.first);
      }

      bluetooth.printNewLine();
      bluetooth.printCustom("Laporan Laba Rugi", 2, 1);
      bluetooth.printNewLine();

      String modeText = "";
      String dateText = "";

      if (_selectedFilterIndex == 0 && _selectedDate != null) {
        modeText = "Harian";
        dateText = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
        modeText = "Bulanan";
        dateText = DateFormat('yyyy-MM').format(_selectedMonth!);
      } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
        modeText = "Tahunan";
        dateText = DateFormat('yyyy').format(_selectedYear!);
      }

      bluetooth.printCustom("Mode: $modeText", 1, 0);
      bluetooth.printCustom("Periode: $dateText", 1, 0);
      bluetooth.printNewLine();
      bluetooth.printCustom(
        "Penjualan: ${currencyFormatter.format(totalPenjualan)}",
        1,
        0,
      );
      bluetooth.printCustom(
        "Pembelian: ${currencyFormatter.format(totalPembelian)}",
        1,
        0,
      );
      bluetooth.printCustom(
        "Operasional: ${currencyFormatter.format(totalOperasional)}",
        1,
        0,
      );
      bluetooth.printNewLine();
      final labaBersih = totalPenjualan - totalPembelian - totalOperasional;
      bluetooth.printCustom(
        "Laba Bersih: ${currencyFormatter.format(labaBersih)}",
        2,
        1,
      );
      bluetooth.printNewLine();
      bluetooth.printNewLine();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mencetak: $e")));
    }
  }

  void onSharePDF() async {
    final pdf = pw.Document();

    final labaBersih = totalPenjualan - totalPembelian - totalOperasional;

    String modeText = "";
    String dateText = "";

    if (_selectedFilterIndex == 0 && _selectedDate != null) {
      modeText = "Harian";
      dateText = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
      modeText = "Bulanan";
      dateText = DateFormat('yyyy-MM').format(_selectedMonth!);
    } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
      modeText = "Tahunan";
      dateText = DateFormat('yyyy').format(_selectedYear!);
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Laba Rugi', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 8),
              pw.Text('Mode: $modeText'),
              pw.Text('Periode: $dateText'),
              pw.Divider(),
              pw.Text('Penjualan: ${currencyFormatter.format(totalPenjualan)}'),
              pw.Text('Pembelian: ${currencyFormatter.format(totalPembelian)}'),
              pw.Text(
                'Operasional: ${currencyFormatter.format(totalOperasional)}',
              ),
              pw.Divider(),
              pw.Text(
                'Laba Bersih: ${currencyFormatter.format(labaBersih)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/laporan_laba_rugi.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareFiles([file.path], text: 'Laporan Laba Rugi');
  }

  void onSendWhatsApp() async {
    final labaBersih = totalPenjualan - totalPembelian - totalOperasional;

    String modeText = "";
    String dateText = "";

    if (_selectedFilterIndex == 0 && _selectedDate != null) {
      modeText = "Harian";
      dateText = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
      modeText = "Bulanan";
      dateText = DateFormat('yyyy-MM').format(_selectedMonth!);
    } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
      modeText = "Tahunan";
      dateText = DateFormat('yyyy').format(_selectedYear!);
    }

    final message =
        '''
Laporan Laba Rugi ($modeText - $dateText)
Penjualan: ${currencyFormatter.format(totalPenjualan)}
Pembelian: ${currencyFormatter.format(totalPembelian)}
Operasional: ${currencyFormatter.format(totalOperasional)}
Laba Bersih: ${currencyFormatter.format(labaBersih)}
''';

    final url = Uri.encodeFull('https://wa.me/?text=$message');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tidak bisa membuka WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final labaBersih = totalPenjualan - totalPembelian - totalOperasional;

    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Laba Rugi'),
        //backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchLabaRugi,
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
                _buildFilterTab('Tahunan', 2),
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
              _selectedYear != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton(
                onPressed: _resetFilters,
                child: Text('Reset Filter'),
              ),
            ),

          // Garis pemisah
          Divider(height: 1),

          // Data Laporan
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      children: [
                        LaporanItem(
                          label: 'Total Penjualan',
                          value: currencyFormatter.format(totalPenjualan),
                        ),
                        Divider(),
                        LaporanItem(
                          label: 'Total Pembelian',
                          value: currencyFormatter.format(totalPembelian),
                        ),
                        LaporanItem(
                          label: 'Biaya Operasional',
                          value: currencyFormatter.format(totalOperasional),
                        ),
                        Divider(thickness: 2),
                        LaporanItem(
                          label: 'Laba Bersih',
                          value: currencyFormatter.format(labaBersih),
                          isBold: true,
                          valueColor: labaBersih >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                  ),
          ),

          Divider(),

          // Tombol aksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: onPrint,
                  icon: Icon(Icons.print),
                  label: Text('Print'),
                ),
                ElevatedButton.icon(
                  onPressed: onSharePDF,
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Share PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: onSendWhatsApp,
                  icon: Icon(Icons.share),
                  label: Text('WhatsApp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaporanItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const LaporanItem({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          )
        : TextStyle(fontSize: 16);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
