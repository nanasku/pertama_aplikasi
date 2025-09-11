const express = require('express');
const router = express.Router();
const db = require('../db');

// GET semua transaksi penjualan
router.get('/', (req, res) => {
  const query = `
    SELECT 
      pj.*, 
      pl.nama as nama_penjual, 
      h.name as nama_barang,
      pj.jenis_barang,
      pj.harga_satuan,
      pj.jumlah,
      pj.total_harga
    FROM penjualan pj
    LEFT JOIN penjual pl ON pj.id_penjual = pl.id
    LEFT JOIN harga_jual h ON pj.id_barang = h.id
    ORDER BY pj.tanggal DESC
  `;
  
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.json(results);
  });
});

// GET penjualan by ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const query = `
    SELECT 
      pj.*, 
      pl.nama as nama_penjual, 
      h.name as nama_barang,
      pj.jenis_barang,
      pj.harga_satuan,
      pj.jumlah,
      pj.total_harga
    FROM penjualan pj
    LEFT JOIN penjual pl ON pj.id_penjual = pl.id
    LEFT JOIN harga_jual h ON pj.id_barang = h.id
    WHERE pj.id = ?
  `;
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error fetching penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ error: 'Transaksi penjualan not found' });
    }
    
    res.json(results[0]);
  });
});

// POST tambah transaksi penjualan
router.post('/', (req, res) => {
  const { 
    id_penjual, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal 
  } = req.body;
  
  const query = `
    INSERT INTO penjualan 
    (id_penjual, id_barang, jenis_barang, harga_satuan, jumlah, total_harga, tanggal) 
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `;
  
  const values = [
    id_penjual, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal || new Date()
  ];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error creating penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.status(201).json({ 
      message: 'Transaksi penjualan created successfully', 
      id: results.insertId 
    });
  });
});

// PUT update transaksi penjualan
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { 
    id_penjual, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal 
  } = req.body;
  
  const query = `
    UPDATE penjualan 
    SET id_penjual = ?, id_barang = ?, jenis_barang = ?, harga_satuan = ?, 
        jumlah = ?, total_harga = ?, tanggal = ? 
    WHERE id = ?
  `;
  
  const values = [
    id_penjual, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal, 
    id
  ];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error updating penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaksi penjualan not found' });
    }
    
    res.json({ message: 'Transaksi penjualan updated successfully' });
  });
});

// DELETE transaksi penjualan
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM penjualan WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error deleting penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaksi penjualan not found' });
    }
    
    res.json({ message: 'Transaksi penjualan deleted successfully' });
  });
});

module.exports = router;