const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/test', (req, res) => {
  res.json({ message: 'Stok route is working!' });
});

module.exports = router;

// ==============================
// GET all stok
// ==============================
router.get('/', (req, res) => {
  const query = 'SELECT * FROM stok ORDER BY id ASC';
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err });
    res.json(results);
  });
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

// ==============================
// POST: Tambah data stok
// ==============================
// POST: Simpan hasil stok opname
router.post('/opname', (req, res) => {
  const {
    nama_kayu,
    kriteria,
    diameter,
    panjang,
    stok_opname,
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
      return res.status(404).json({ error: 'Data stok tidak ditemukan untuk data opname ini' });
    }

    const stok_buku = results[0].stok_buku;
    const selisih = stok_opname - stok_buku;

    const insertOpnameQuery = `
      INSERT INTO stok_opname (
        nama_kayu, kriteria, diameter, panjang, stok_buku,
        stok_opname, selisih, tanggal_opname, keterangan
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
      insertOpnameQuery,
      [nama_kayu, kriteria, diameter, panjang, stok_buku, stok_opname, selisih, tanggal_opname, keterangan],
      (insertErr, result) => {
        if (insertErr) {
          console.error('Gagal menyimpan opname:', insertErr);
          return res.status(500).json({ error: 'Gagal menyimpan data opname' });
        }

        return res.status(201).json({ message: 'Opname berhasil disimpan', id: result.insertId });
      }
    );
  });
});

// ==============================
// PUT: Update data stok
// ==============================
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
