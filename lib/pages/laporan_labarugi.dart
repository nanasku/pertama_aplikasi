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

  String mode = 'Harian'; // 'Harian', 'Bulanan', 'Tahunan'
  DateTime selectedDate = DateTime.now();

  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchLabaRugi();
  }

  Future<void> fetchLabaRugi() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final formattedMonth = DateFormat('yyyy-MM').format(selectedDate);
      final formattedYear = DateFormat('yyyy').format(selectedDate);

      String param;
        if (mode == 'Harian') {
          param = '?tanggal=$formattedDate';
        } else if (mode == 'Bulanan') {
          param = '?bulan=$formattedMonth';
        } else {
          param = '?tahun=${selectedDate.year}';
        }

      final pembelianRes =
          await http.get(Uri.parse('${dotenv.env['API_BASE_URL']}/pembelian$param'));
      final penjualanRes =
          await http.get(Uri.parse('${dotenv.env['API_BASE_URL']}/penjualan$param'));

      if (pembelianRes.statusCode == 200 &&
          penjualanRes.statusCode == 200) {
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

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDatePickerMode: mode == 'Tahunan'
          ? DatePickerMode.year
          : DatePickerMode.day,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      fetchLabaRugi();
    }
  }

  void pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      fetchLabaRugi();
    }
  }

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

        // Bisa tambahkan UI untuk pilih device di sini
        bluetooth.connect(devices.first); // Default pilih yang pertama
      }

      bluetooth.printNewLine();
      bluetooth.printCustom("Laporan Laba Rugi", 2, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Mode: $mode", 1, 0);
      bluetooth.printCustom("Tanggal: ${DateFormat('yyyy-MM-dd').format(selectedDate)}", 1, 0);
      bluetooth.printNewLine();
      bluetooth.printCustom("Penjualan: ${currencyFormatter.format(totalPenjualan)}", 1, 0);
      bluetooth.printCustom("Pembelian: ${currencyFormatter.format(totalPembelian)}", 1, 0);
      bluetooth.printCustom("Operasional: ${currencyFormatter.format(totalOperasional)}", 1, 0);
      bluetooth.printNewLine();
      final labaBersih = totalPenjualan - totalPembelian - totalOperasional;
      bluetooth.printCustom("Laba Bersih: ${currencyFormatter.format(labaBersih)}", 2, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mencetak: $e")),
      );
    }
  }

  void onSharePDF() async {
    final pdf = pw.Document();

    final labaBersih = totalPenjualan - totalPembelian - totalOperasional;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Laba Rugi', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 8),
              pw.Text('Mode: $mode'),
              pw.Text('Tanggal: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
              pw.Divider(),
              pw.Text('Penjualan: ${currencyFormatter.format(totalPenjualan)}'),
              pw.Text('Pembelian: ${currencyFormatter.format(totalPembelian)}'),
              pw.Text('Operasional: ${currencyFormatter.format(totalOperasional)}'),
              pw.Divider(),
              pw.Text('Laba Bersih: ${currencyFormatter.format(labaBersih)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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

    final message = '''
  Laporan Laba Rugi ($mode - ${DateFormat('yyyy-MM-dd').format(selectedDate)})
  Penjualan: ${currencyFormatter.format(totalPenjualan)}
  Pembelian: ${currencyFormatter.format(totalPembelian)}
  Operasional: ${currencyFormatter.format(totalOperasional)}
  Laba Bersih: ${currencyFormatter.format(labaBersih)}
  ''';

    final url = Uri.encodeFull('https://wa.me/?text=$message');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak bisa membuka WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final labaBersih = totalPenjualan - totalPembelian - totalOperasional;

    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Laba Rugi'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 🔼 Bagian atas: mode dan tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToggleButtons(
                  isSelected: [mode == 'Harian', mode == 'Bulanan', mode == 'Tahunan'],
                  onPressed: (index) {
                    setState(() {
                      mode = index == 0
                          ? 'Harian'
                          : index == 1
                              ? 'Bulanan'
                              : 'Tahunan';
                    });
                    fetchLabaRugi();
                  },
                  children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Harian')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Bulanan')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Tahunan')),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: mode == 'Harian' ? pickDate : pickMonth,
                      icon: Icon(Icons.calendar_today),
                      label: Text(
                        mode == 'Harian'
                            ? DateFormat('dd MMM yyyy').format(selectedDate)
                            : mode == 'Bulanan'
                                ? DateFormat('MMMM yyyy').format(selectedDate)
                                : DateFormat('yyyy').format(selectedDate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(),

          // 🔽 Bagian tengah: isi laporan
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
                              value:
                                  currencyFormatter.format(totalOperasional),
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

          // 🔘 Bagian bawah: tombol aksi
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
            color: valueColor ?? Colors.black)
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
