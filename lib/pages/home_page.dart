// home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      // Ambil data pembelian hari ini
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final pembelianResponse = await ApiService().get(
        '/pembelian?tanggal=$today',
      );

      // Ambil data penjualan hari ini
      final penjualanResponse = await ApiService().get(
        '/penjualan?tanggal=$today',
      );

      // Debug: Print struktur data untuk pemecahan masalah
      print('Pembelian response: $pembelianResponse');
      print('Penjualan response: $penjualanResponse');

      return {
        'pembelian': pembelianResponse is List ? pembelianResponse : [],
        'penjualan': penjualanResponse is List ? penjualanResponse : [],
      };
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return {'pembelian': [], 'penjualan': []};
    }
  }

  // Fungsi untuk mendapatkan detail pembelian/penjualan berdasarkan ID
  Future<List<dynamic>> _fetchDetail(String type, int id, String faktur) async {
    try {
      // Coba ambil detail dari endpoint yang sesuai
      final response = await ApiService().get('/$type/$id');
      print('Detail response for $type $id: $response');

      // Jika response memiliki field 'detail', kembalikan itu
      if (response is Map && response.containsKey('detail')) {
        return response['detail'] is List ? response['detail'] : [];
      }

      // Jika tidak ada detail, coba ambil dari endpoint khusus
      final detailResponse = await ApiService().get('/$type/detail/$faktur');
      return detailResponse is List ? detailResponse : [];
    } catch (e) {
      print('Error fetching detail for $type $id: $e');
      return [];
    }
  }

  // Hitung total volume per kriteria dengan fetching detail terlebih dahulu
  Future<Map<String, double>> _calculateVolumeByCriteria(
    List<dynamic> transactions,
    String type,
  ) async {
    Map<String, double> volumeByCriteria = {};

    for (var transaction in transactions) {
      try {
        final id = transaction['id'] ?? transaction['ID'];
        final faktur =
            transaction['faktur_${type == 'pembelian' ? 'pemb' : 'penj'}'] ??
            transaction['faktur'] ??
            transaction['no_faktur'];

        if (id != null && faktur != null) {
          final details = await _fetchDetail(type, id, faktur);

          for (var detail in details) {
            String kriteria =
                detail['kriteria']?.toString() ??
                detail['Kriteria']?.toString() ??
                'Unknown';

            // Coba berbagai kemungkinan field volume
            double volume =
                double.tryParse(
                  detail['volume']?.toString() ??
                      detail['Volume']?.toString() ??
                      detail['VOLUME']?.toString() ??
                      '0',
                ) ??
                0;

            // Jika volume 0, coba hitung dari diameter dan panjang
            if (volume == 0) {
              double diameter =
                  double.tryParse(detail['diameter']?.toString() ?? '0') ?? 0;
              double panjang =
                  double.tryParse(detail['panjang']?.toString() ?? '0') ?? 0;
              int jumlah =
                  int.tryParse(detail['jumlah']?.toString() ?? '0') ?? 0;

              // Rumus volume kayu: (diameter^2 * panjang * jumlah * 0.7854) / 1,000,000,000
              if (diameter > 0 && panjang > 0 && jumlah > 0) {
                volume =
                    (diameter * diameter * panjang * jumlah * 0.7854) /
                    1000000000;
              }
            }

            if (volume > 0) {
              if (volumeByCriteria.containsKey(kriteria)) {
                volumeByCriteria[kriteria] =
                    volumeByCriteria[kriteria]! + volume;
              } else {
                volumeByCriteria[kriteria] = volume;
              }
            }
          }
        }
      } catch (e) {
        print('Error processing transaction: $e');
      }
    }

    return volumeByCriteria;
  }

  // Format volume ke meter kubik dengan 2 desimal
  String _formatVolume(double volume) {
    return '${volume.toStringAsFixed(2)} cm³';
  }

  // Widget card untuk menampilkan statistik
  Widget _buildStatCard(
    String title,
    int count,
    Map<String, double> volumeData,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    title.contains('Pembelian')
                        ? Icons.shopping_cart
                        : Icons.sell,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$count Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Volume per Kriteria:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (volumeData.isEmpty)
              Text(
                'Tidak ada data volume',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: volumeData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key.isEmpty
                                ? 'Tidak ada kriteria'
                                : entry.key,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _formatVolume(entry.value),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Widget untuk aktivitas terakhir
  Widget _buildRecentActivity(
    List<dynamic> pembelian,
    List<dynamic> penjualan,
  ) {
    List<Map<String, dynamic>> allActivities = [];

    // Process pembelian
    for (var p in pembelian) {
      allActivities.add({
        'type': 'pembelian',
        'faktur':
            p['faktur_pemb'] ?? p['faktur'] ?? p['no_faktur'] ?? 'No Faktur',
        'nama': p['nama_penjual'] ?? p['penjual'] ?? 'Supplier',
        'total': p['total'] ?? 0,
        'time': p['created_at'] ?? p['tanggal'] ?? DateTime.now().toString(),
        'icon': Icons.shopping_cart,
        'color': Colors.green,
      });
    }

    // Process penjualan
    for (var p in penjualan) {
      allActivities.add({
        'type': 'penjualan',
        'faktur':
            p['faktur_penj'] ?? p['faktur'] ?? p['no_faktur'] ?? 'No Faktur',
        'nama': p['nama_pembeli'] ?? p['pembeli'] ?? 'Customer',
        'total': p['total'] ?? 0,
        'time': p['created_at'] ?? p['tanggal'] ?? DateTime.now().toString(),
        'icon': Icons.sell,
        'color': Colors.blue,
      });
    }

    // Urutkan berdasarkan waktu
    allActivities.sort((a, b) => b['time'].compareTo(a['time']));

    final recentActivities = allActivities.take(5).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Aktivitas Terakhir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentActivities.isEmpty)
              Center(
                child: Text(
                  'Tidak ada aktivitas hari ini',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: recentActivities.map((activity) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activity['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity['icon'],
                            color: activity['color'],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${activity['type'] == 'pembelian' ? 'Pembelian' : 'Penjualan'} - ${activity['faktur']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                activity['nama'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${NumberFormat('#,##0').format(activity['total'])}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: activity['color'],
                              ),
                            ),
                            Text(
                              _formatTime(activity['time']),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('HH:mm').format(parsedDate);
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildQuickStat(
    String title,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data dashboard...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _dashboardData = _fetchDashboardData();
                      });
                    },
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final pembelianHariIni = data['pembelian'] as List;
          final penjualanHariIni = data['penjualan'] as List;

          return FutureBuilder(
            future: Future.wait([
              _calculateVolumeByCriteria(pembelianHariIni, 'pembelian'),
              _calculateVolumeByCriteria(penjualanHariIni, 'penjualan'),
            ]),
            builder: (context, volumeSnapshot) {
              if (volumeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final volumePembelian = volumeSnapshot.data?[0] ?? {};
              final volumePenjualan = volumeSnapshot.data?[1] ?? {};

              final totalVolume =
                  volumePembelian.values.fold(0.0, (a, b) => a + b) +
                  volumePenjualan.values.fold(0.0, (a, b) => a + b);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.forest, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard Kayu',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy',
                              ).format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Grid Statistik
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Pembelian Hari Ini',
                            pembelianHariIni.length,
                            volumePembelian,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Penjualan Hari Ini',
                            penjualanHariIni.length,
                            volumePenjualan,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Aktivitas Terakhir
                    _buildRecentActivity(pembelianHariIni, penjualanHariIni),
                    const SizedBox(height: 16),

                    // Quick Stats
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickStat(
                              'Total Pembelian',
                              pembelianHariIni.length,
                              Icons.shopping_cart,
                              Colors.green,
                            ),
                            _buildQuickStat(
                              'Total Penjualan',
                              penjualanHariIni.length,
                              Icons.sell,
                              Colors.blue,
                            ),
                            _buildQuickStat(
                              'Volume Total',
                              '${totalVolume.toStringAsFixed(1)} cm³',
                              Icons.analytics,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _dashboardData = _fetchDashboardData();
          });
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
