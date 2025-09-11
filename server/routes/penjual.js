const express = require('express');
const router = express.Router();
const db = require('../db');

// GET semua penjual dengan pencarian
router.get('/', (req, res) => {
  const { search } = req.query;
  let query = 'SELECT * FROM penjual';
  let params = [];
  
  if (search) {
    query += ' WHERE nama LIKE ? OR alamat LIKE ? OR telepon LIKE ? OR email LIKE ?';
    const searchPattern = `%${search}%`;
    params = [searchPattern, searchPattern, searchPattern, searchPattern];
  }
  
  query += ' ORDER BY nama';
  
  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Error fetching penjual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.json(results);
  });
});

// GET penjual by ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'SELECT * FROM penjual WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error fetching penjual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ error: 'Penjual not found' });
    }
    
    res.json(results[0]);
  });
});

// POST tambah penjual
router.post('/', (req, res) => {
  const { nama, alamat, telepon, email } = req.body;
  
  const query = 'INSERT INTO penjual (nama, alamat, telepon, email) VALUES (?, ?, ?, ?)';
  const values = [nama, alamat, telepon, email];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error creating penjual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.status(201).json({ 
      message: 'Penjual created successfully', 
      id: results.insertId 
    });
  });
});

// PUT update penjual
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { nama, alamat, telepon, email } = req.body;
  
  const query = 'UPDATE penjual SET nama = ?, alamat = ?, telepon = ?, email = ? WHERE id = ?';
  const values = [nama, alamat, telepon, email, id];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error updating penjual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Penjual not found' });
    }
    
    res.json({ message: 'Penjual updated successfully' });
  });
});

// DELETE penjual
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM penjual WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error deleting penjual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Penjual not found' });
    }
    
    res.json({ message: 'Penjual deleted successfully' });
  });
});

module.exports = router;