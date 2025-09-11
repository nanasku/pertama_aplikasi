const express = require('express');
const router = express.Router();
const db = require('../db');

// GET semua pembeli dengan pencarian
router.get('/', (req, res) => {
  const { search } = req.query;
  let query = 'SELECT * FROM pembeli';
  let params = [];
  
  if (search) {
    query += ' WHERE nama LIKE ? OR alamat LIKE ? OR telepon LIKE ? OR email LIKE ?';
    const searchPattern = `%${search}%`;
    params = [searchPattern, searchPattern, searchPattern, searchPattern];
  }
  
  query += ' ORDER BY nama';
  
  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Error fetching pembeli:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.json(results);
  });
});

// GET pembeli by ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'SELECT * FROM pembeli WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error fetching pembeli:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ error: 'Pembeli not found' });
    }
    
    res.json(results[0]);
  });
});

// POST tambah pembeli
router.post('/', (req, res) => {
  const { nama, alamat, telepon, email } = req.body;
  
  const query = 'INSERT INTO pembeli (nama, alamat, telepon, email) VALUES (?, ?, ?, ?)';
  const values = [nama, alamat, telepon, email];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error creating pembeli:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.status(201).json({ 
      message: 'Pembeli created successfully', 
      id: results.insertId 
    });
  });
});

// PUT update pembeli
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { nama, alamat, telepon, email } = req.body;
  
  const query = 'UPDATE pembeli SET nama = ?, alamat = ?, telepon = ?, email = ? WHERE id = ?';
  const values = [nama, alamat, telepon, email, id];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error updating pembeli:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Pembeli not found' });
    }
    
    res.json({ message: 'Pembeli updated successfully' });
  });
});

// DELETE pembeli
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM pembeli WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error deleting pembeli:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Pembeli not found' });
    }
    
    res.json({ message: 'Pembeli deleted successfully' });
  });
});

module.exports = router;