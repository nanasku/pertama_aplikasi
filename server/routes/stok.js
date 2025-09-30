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

  // Di router.get('/laporan'), perbaiki query untuk konversi ke cm³:
  const query = `
    SELECT 
      s.nama_kayu,
      s.kriteria,
      s.diameter,
      s.panjang,
      COALESCE(sa.stok_awal, 0) AS stok_awal,
      COALESCE(SUM(pb.jumlah), 0) AS stok_pembelian,
      COALESCE(SUM(pj.jumlah), 0) AS stok_penjualan,
      (COALESCE(sa.stok_awal, 0) + COALESCE(SUM(pb.jumlah),0) - COALESCE(SUM(pj.jumlah),0)) AS stok_akhir,
      -- 🆕 Hitung total volume dalam m³ (TANPA konversi ke cm³)
      ROUND(
        (
          COALESCE(SUM(pb.volume * pb.jumlah), 0) - 
          COALESCE(SUM(pj.volume * pj.jumlah), 0)
        ), 0
      ) AS total_volume
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

// POST: Simpan hasil stok opname
router.post('/opname', (req, res) => {
  const {
    nama_kayu,
    kriteria,
    diameter,
    panjang,
    stok_opname,
    stok_rusak = 0,
    tanggal_opname,
    keterangan
  } = req.body;

  if (
    !nama_kayu || !kriteria || !diameter || !panjang ||
    stok_opname === undefined || !tanggal_opname
  ) {
    return res.status(400).json({ error: 'Data opname tidak lengkap' });
  }

  const selectStokQuery = `
    SELECT stok_buku FROM stok
    WHERE nama_kayu = ? AND kriteria = ? AND diameter = ? AND panjang = ?
    LIMIT 1
  `;

  db.query(selectStokQuery, [nama_kayu, kriteria, diameter, panjang], (err, results) => {
    if (err) {
      console.error('Gagal mengambil stok:', err);
      return res.status(500).json({ error: 'Gagal mengambil data stok' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Data stok tidak ditemukan untuk opname ini' });
    }

    const stok_buku = results[0].stok_buku;
    const selisih = stok_opname - stok_buku;

    // ✅ 1. Simpan ke tabel stok_opname
    const insertOpnameQuery = `
      INSERT INTO stok_opname (
        nama_kayu, kriteria, diameter, panjang, stok_buku,
        stok_opname, stok_rusak, selisih, tanggal_opname, keterangan
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
      insertOpnameQuery,
      [
        nama_kayu, kriteria, diameter, panjang, stok_buku,
        stok_opname, stok_rusak, selisih, tanggal_opname, keterangan
      ],
      (insertErr, result) => {
        if (insertErr) {
          console.error('Gagal menyimpan opname:', insertErr);
          return res.status(500).json({ error: 'Gagal menyimpan data opname' });
        }

        // ✅ 2. Kurangi stok_buku dari tabel stok jika ada rusak
        if (stok_rusak > 0) {
          const updateStokQuery = `
            UPDATE stok
            SET stok_buku = GREATEST(stok_buku - ?, 0)
            WHERE nama_kayu = ? AND kriteria = ? AND diameter = ? AND panjang = ?
          `;

          db.query(
            updateStokQuery,
            [stok_rusak, nama_kayu, kriteria, diameter, panjang],
            (updateErr, updateResult) => {
              if (updateErr) {
                console.error('Gagal mengurangi stok:', updateErr);
                return res.status(500).json({ error: 'Gagal mengurangi stok akibat rusak' });
              }

              return res.status(201).json({
                message: 'Opname berhasil disimpan dan stok dikurangi',
                id: result.insertId
              });
            }
          );
        } else {
          return res.status(201).json({ message: 'Opname berhasil disimpan', id: result.insertId });
        }
      }
    );
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
