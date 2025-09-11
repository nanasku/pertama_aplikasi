const express = require('express');
const router = express.Router();
const db = require('../db');

// GET semua transaksi pembelian
router.get('/', (req, res) => {
  const query = `
    SELECT 
      pb.*, 
      pl.nama as nama_pembeli, 
      h.name as nama_barang,
      pb.jenis_barang,
      pb.harga_satuan,
      pb.jumlah,
      pb.total_harga
    FROM pembelian pb
    LEFT JOIN pembeli pl ON pb.id_pembeli = pl.id
    LEFT JOIN harga_beli h ON pb.id_barang = h.id
    ORDER BY pb.tanggal DESC
  `;
  
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.json(results);
  });
});

// GET pembelian by ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const query = `
    SELECT 
      pb.*, 
      pl.nama as nama_pembeli, 
      h.name as nama_barang,
      pb.jenis_barang,
      pb.harga_satuan,
      pb.jumlah,
      pb.total_harga
    FROM pembelian pb
    LEFT JOIN pembeli pl ON pb.id_pembeli = pl.id
    LEFT JOIN harga_beli h ON pb.id_barang = h.id
    WHERE pb.id = ?
  `;
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error fetching pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ error: 'Transaksi pembelian not found' });
    }
    
    res.json(results[0]);
  });
});

// POST tambah transaksi pembelian
router.post('/', (req, res) => {
  const { 
    id_pembeli, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal 
  } = req.body;
  
  const query = `
    INSERT INTO pembelian 
    (id_pembeli, id_barang, jenis_barang, harga_satuan, jumlah, total_harga, tanggal) 
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `;
  
  const values = [
    id_pembeli, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal || new Date()
  ];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error creating pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.status(201).json({ 
      message: 'Transaksi pembelian created successfully', 
      id: results.insertId 
    });
  });
});

// PUT update transaksi pembelian
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { 
    id_pembeli, 
    id_barang, 
    jenis_barang, 
    harga_satuan, 
    jumlah, 
    total_harga, 
    tanggal 
  } = req.body;
  
  const query = `
    UPDATE pembelian 
    SET id_pembeli = ?, id_barang = ?, jenis_barang = ?, harga_satuan = ?, 
        jumlah = ?, total_harga = ?, tanggal = ? 
    WHERE id = ?
  `;
  
  const values = [
    id_pembeli, 
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
      console.error('Error updating pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaksi pembelian not found' });
    }
    
    res.json({ message: 'Transaksi pembelian updated successfully' });
  });
});

// DELETE transaksi pembelian
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM pembelian WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error deleting pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaksi pembelian not found' });
    }
    
    res.json({ message: 'Transaksi pembelian deleted successfully' });
  });
});

module.exports = router;