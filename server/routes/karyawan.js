const express = require('express');
const router = express.Router();
const db = require('../db'); // koneksi dari db.js

// GET: Generate kode otomatis
router.get('/generate-kode', (req, res) => {
  const sql = 'SELECT MAX(kode_kry) AS maxKode FROM karyawan';
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: 'Gagal generate kode' });

    const maxKode = results[0].maxKode;
    let nextKode = 'KRY001';
    
    if (maxKode) {
      const num = parseInt(maxKode.slice(3)) + 1;
      nextKode = 'KRY' + num.toString().padStart(3, '0');
    }

    res.json({ kode_kry: nextKode });
  });
});

// GET: Ambil semua karyawan
router.get('/', (req, res) => {
  const sql = 'SELECT * FROM karyawan';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching karyawan:', err);
      return res.status(500).json({ error: 'Gagal mengambil data karyawan' });
    }
    res.json(results);
  });
});

// GET: Ambil 1 karyawan berdasarkan ID
router.get('/:id', (req, res) => {
  const sql = 'SELECT * FROM karyawan WHERE id = ?';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Error mengambil data' });
    if (results.length === 0) return res.status(404).json({ message: 'Karyawan tidak ditemukan' });
    res.json(results[0]);
  });
});

// POST: Tambah data karyawan dengan generate kode_kry otomatis
router.post('/', (req, res) => {
  const { user, psw, nama, alamat, telepon, email } = req.body;

  // Langkah 1: Ambil kode_kry terakhir
  const getLastCodeSql = `
    SELECT kode_kry FROM karyawan 
    WHERE kode_kry LIKE 'KRY%' 
    ORDER BY kode_kry DESC 
    LIMIT 1
  `;

  db.query(getLastCodeSql, (err, results) => {
    if (err) {
      console.error('Gagal mengambil kode terakhir:', err);
      return res.status(500).json({ error: 'Gagal generate kode karyawan' });
    }

    // Langkah 2: Generate kode baru
    let newCode = 'KRY001'; // default jika kosong
    if (results.length > 0) {
      const lastCode = results[0].kode_kry;
      const lastNumber = parseInt(lastCode.replace('KRY', '')) || 0;
      const nextNumber = lastNumber + 1;
      newCode = 'KRY' + nextNumber.toString().padStart(3, '0');
    }

    // Langkah 3: Simpan data karyawan
    const insertSql = `
      INSERT INTO karyawan (kode_kry, user, psw, nama, alamat, telepon, email)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
      insertSql,
      [newCode, user, psw, nama, alamat, telepon, email],
      (err, result) => {
        if (err) {
          console.error('Gagal menambahkan karyawan:', err);
          return res.status(500).json({ error: 'Gagal menambahkan karyawan' });
        }

        res.json({
          message: 'Karyawan berhasil ditambahkan',
          id: result.insertId,
          kode_kry: newCode,
        });
      }
    );
  });
});

// PUT: Update data karyawan
router.put('/:id', (req, res) => {
  const { kode_kry, user, psw, nama, alamat, telepon, email } = req.body;
  const sql = `
    UPDATE karyawan SET kode_kry = ?, user = ?, psw = ?, nama = ?, alamat = ?, telepon = ?, email = ?
    WHERE id = ?
  `;
  db.query(sql, [kode_kry, user, psw, nama, alamat, telepon, email, req.params.id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Gagal mengupdate data' });
    res.json({ message: 'Data karyawan berhasil diupdate' });
  });
});

// DELETE: Hapus karyawan
router.delete('/:id', (req, res) => {
  const sql = 'DELETE FROM karyawan WHERE id = ?';
  db.query(sql, [req.params.id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Gagal menghapus data' });
    res.json({ message: 'Data karyawan berhasil dihapus' });
  });
});

module.exports = router;
