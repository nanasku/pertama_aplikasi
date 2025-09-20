class SaleItem {
  final String id;
  final String kriteria;
  final double diameter;
  final double panjang;
  final int jumlah;
  final double volume;
  final int harga;
  final int jumlahHarga;

  SaleItem({
    required this.id,
    required this.kriteria,
    required this.diameter,
    required this.panjang,
    required this.jumlah,
    required this.volume,
    required this.harga,
    required this.jumlahHarga,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kriteria': kriteria,
      'diameter': diameter,
      'panjang': panjang,
      'jumlah': jumlah,
      'volume': volume,
      'harga': harga,
      'jumlahHarga': jumlahHarga,
    };
  }

  // Create from Map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      kriteria: map['kriteria'],
      diameter: map['diameter'],
      panjang: map['panjang'],
      jumlah: map['jumlah'],
      volume: map['volume'],
      harga: map['harga'],
      jumlahHarga: map['jumlahHarga'],
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
  final int stokBuku;

  StokData({
    required this.kriteria,
    required this.namaKayu,
    required this.diameter,
    required this.panjang,
    required this.stokPembelian,
    required this.stokPenjualan,
    required this.stokRusak,
    required this.stokBuku,
  });

  int get stokAkhir => stokPembelian - (stokPenjualan + stokRusak);
}
