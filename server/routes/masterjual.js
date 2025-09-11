const express = require('express');
const router = express.Router();
const db = require('../db');

// GET semua data harga jual
router.get('/', (req, res) => {
  const query = 'SELECT * FROM harga_jual ORDER BY name';
  
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching harga jual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    // Format data sesuai dengan struktur frontend
    const formattedResults = results.map(item => ({
      id: item.id,
      name: item.name,
      prices: {
        'Rijek 1': item.harga_rijek_1,
        'Rijek 2': item.harga_rijek_2,
        'Standar': item.harga_standar,
        'Super A': item.harga_super_a,
        'Super B': item.harga_super_b,
        'Super C': item.harga_super_c
      },
      created_at: item.created_at,
      updated_at: item.updated_at
    }));
    
    res.json(formattedResults);
  });
});

// GET data harga jual by ID
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'SELECT * FROM harga_jual WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error fetching harga jual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ error: 'Data not found' });
    }
    
    const item = results[0];
    const formattedResult = {
      id: item.id,
      name: item.name,
      prices: {
        'Rijek 1': item.harga_rijek_1,
        'Rijek 2': item.harga_rijek_2,
        'Standar': item.harga_standar,
        'Super A': item.harga_super_a,
        'Super B': item.harga_super_b,
        'Super C': item.harga_super_c
      },
      created_at: item.created_at,
      updated_at: item.updated_at
    };
    
    res.json(formattedResult);
  });
});

// POST tambah data harga jual
router.post('/', (req, res) => {
  const { name, prices } = req.body;
  
  const query = `
    INSERT INTO harga_jual 
    (name, harga_rijek_1, harga_rijek_2, harga_standar, harga_super_a, harga_super_b, harga_super_c) 
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `;
  
  const values = [
    name,
    prices['Rijek 1'] || 0,
    prices['Rijek 2'] || 0,
    prices['Standar'] || 0,
    prices['Super A'] || 0,
    prices['Super B'] || 0,
    prices['Super C'] || 0
  ];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error creating harga jual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    res.status(201).json({ 
      message: 'Data created successfully', 
      id: results.insertId 
    });
  });
});

// PUT update data harga jual
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { name, prices } = req.body;
  
  const query = `
    UPDATE harga_jual 
    SET name = ?, harga_rijek_1 = ?, harga_rijek_2 = ?, harga_standar = ?, 
        harga_super_a = ?, harga_super_b = ?, harga_super_c = ?, updated_at = CURRENT_TIMESTAMP 
    WHERE id = ?
  `;
  
  const values = [
    name,
    prices['Rijek 1'] || 0,
    prices['Rijek 2'] || 0,
    prices['Standar'] || 0,
    prices['Super A'] || 0,
    prices['Super B'] || 0,
    prices['Super C'] || 0,
    id
  ];
  
  db.query(query, values, (err, results) => {
    if (err) {
      console.error('Error updating harga jual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Data not found' });
    }
    
    res.json({ message: 'Data updated successfully' });
  });
});

// DELETE data harga jual
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM harga_jual WHERE id = ?';
  
  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error deleting harga jual:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ error: 'Data not found' });
    }
    
    res.json({ message: 'Data deleted successfully' });
  });
});

module.exports = router;