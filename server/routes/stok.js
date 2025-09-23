const express = require('express');
const router = express.Router();
const db = require('../db');

// GET: semua stok (hasil view)
router.get('/', (req, res) => {
  const query = `SELECT * FROM stok ORDER BY nama_kayu, kriteria, diameter, panjang`;
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error ambil stok:', err);
      return res.status(500).json({ error: 'Gagal ambil stok' });
    }
    res.json(results);
  });
});

// GET: stok berdasarkan nama kayu
router.get('/by-nama', (req, res) => {
  const { nama_kayu } = req.query;
  if (!nama_kayu) {
    return res.status(400).json({ error: 'Parameter nama_kayu wajib' });
  }
  const query = `SELECT * FROM stok WHERE nama_kayu = ? ORDER BY kriteria, diameter, panjang`;
  db.query(query, [nama_kayu], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    res.json(results);
  });
});

// ==============================
// GET: Laporan Stok
// ==============================
router.get('/laporan', (req, res) => {
  const { tahun, bulan, nama_kayu } = req.query;

  if (!tahun || !bulan) {
    return res.status(400).json({ error: 'Parameter tahun dan bulan wajib' });
  }

  const query = `
    SELECT 
      s.nama_kayu,
      s.kriteria,
      s.diameter,
      s.panjang,
      COALESCE(sa.stok_awal, 0) AS stok_awal,
      COALESCE(SUM(pb.jumlah), 0) AS stok_pembelian,
      COALESCE(SUM(pj.jumlah), 0) AS stok_penjualan,
      (COALESCE(sa.stok_awal, 0) + COALESCE(SUM(pb.jumlah),0) - COALESCE(SUM(pj.jumlah),0)) AS stok_akhir
    FROM stok s
    LEFT JOIN stok_awal sa
      ON s.nama_kayu = sa.nama_kayu
      AND s.kriteria = sa.kriteria
      AND s.diameter = sa.diameter
      AND s.panjang = sa.panjang
      AND sa.bulan = ?
      AND sa.periode_bulan = ?
    LEFT JOIN pembelian_detail pb
      ON s.nama_kayu = pb.nama_kayu
      AND s.kriteria = pb.kriteria
      AND s.diameter = pb.diameter
      AND s.panjang = pb.panjang
      AND MONTH(pb.created_at) = ?
      AND YEAR(pb.created_at) = ?
    LEFT JOIN penjualan_detail pj
      ON s.nama_kayu = pj.nama_kayu
      AND s.kriteria = pj.kriteria
      AND s.diameter = pj.diameter
      AND s.panjang = pj.panjang
      AND MONTH(pj.created_at) = ?
      AND YEAR(pj.created_at) = ?
    WHERE s.nama_kayu = ?
    GROUP BY s.nama_kayu, s.kriteria, s.diameter, s.panjang, sa.stok_awal
    ORDER BY s.nama_kayu, s.kriteria, s.diameter, s.panjang
  `;

  db.query(
    query,
    [tahun, bulan, bulan, tahun, bulan, tahun, nama_kayu],
    (err, results) => {
      if (err) {
        console.error('Error ambil laporan stok:', err);
        return res.status(500).json({ error: 'Gagal ambil laporan stok' });
      }
      res.json(results);
    }
  );
});

// ==============================
// GET stok by ID
// ==============================
router.get('/:id', (req, res) => {
  const query = 'SELECT * FROM stok WHERE id = ?';
  db.query(query, [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length === 0) return res.status(404).json({ message: 'Stok not found' });
    res.json(results[0]);
  });
});

// POST: input stok opname
router.post('/opname', (req, res) => {
  const { nama_kayu, kriteria, diameter, panjang, stok_opname, tanggal_opname, keterangan } = req.body;

  if (!nama_kayu || !kriteria || !diameter || !panjang || stok_opname === undefined || !tanggal_opname) {
    return res.status(400).json({ error: 'Data opname tidak lengkap' });
  }

  // Ambil stok buku dari view stok
  const selectQuery = `SELECT stok_buku FROM stok WHERE nama_kayu=? AND kriteria=? AND diameter=? AND panjang=? LIMIT 1`;
  db.query(selectQuery, [nama_kayu, kriteria, diameter, panjang], (err, results) => {
    if (err) return res.status(500).json({ error: 'Gagal ambil stok' });
    if (results.length === 0) return res.status(404).json({ error: 'Data stok tidak ditemukan' });

    const stok_buku = results[0].stok_buku;

    const insertQuery = `
      INSERT INTO stok_opname 
        (nama_kayu, kriteria, diameter, panjang, stok_buku, stok_opname, tanggal_opname, keterangan) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    db.query(insertQuery, [nama_kayu, kriteria, diameter, panjang, stok_buku, stok_opname, tanggal_opname, keterangan], (err2, result) => {
      if (err2) {
        console.error('Gagal simpan opname:', err2);
        return res.status(500).json({ error: 'Gagal simpan opname' });
      }
      res.status(201).json({ message: 'Opname berhasil disimpan', id: result.insertId });
    });
  });
});

// PUT: Update data stok
router.put('/:id', (req, res) => {
  const { nama_kayu, kriteria, diameter, panjang, stok_buku } = req.body;
  const query = `
    UPDATE stok
    SET nama_kayu = ?, kriteria = ?, diameter = ?, panjang = ?, stok_buku = ?
    WHERE id = ?
  `;
  db.query(query, [nama_kayu, kriteria, diameter, panjang, stok_buku, req.params.id], (err, result) => {
    if (err) return res.status(500).json({ error: err });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'Stok not found' });
    res.json({ message: 'Stok berhasil diperbarui' });
  });
});

// ==============================
// DELETE: Hapus data stok
// ==============================
router.delete('/:id', (req, res) => {
  const query = 'DELETE FROM stok WHERE id = ?';
  db.query(query, [req.params.id], (err, result) => {
    if (err) return res.status(500).json({ error: err });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'Stok not found' });
    res.json({ message: 'Stok berhasil dihapus' });
  });
});

module.exports = router;
