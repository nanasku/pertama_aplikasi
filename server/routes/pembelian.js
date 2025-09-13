const express = require('express');
const router = express.Router();
const db = require('../db');

// GET semua transaksi pembelian
router.get('/', (req, res) => {
  const query = `
    SELECT 
      pb.*, 
      pl.nama AS nama_penjual, 
      h.nama_kayu AS nama_barang
    FROM pembelian pb
    LEFT JOIN penjual pl ON pb.penjual_id = pl.id
    LEFT JOIN harga_beli h ON pb.product_id = h.id
    ORDER BY pb.created_at DESC
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    res.json(results);
  });
});

// GET pembelian by ID (beserta detail)
router.get('/:id', (req, res) => {
  const { id } = req.params;

  const queryPembelian = `
    SELECT 
      pb.*, 
      pl.nama AS nama_penjual, 
      h.nama_kayu AS nama_barang
    FROM pembelian pb
    LEFT JOIN penjual pl ON pb.penjual_id = pl.id
    LEFT JOIN harga_beli h ON pb.product_id = h.id
    WHERE pb.id = ?
  `;

  const queryDetail = `
    SELECT * FROM pembelian_detail WHERE faktur_pemb = ?
  `;

  db.query(queryPembelian, [id], (err, resultsPembelian) => {
    if (err) {
      console.error('Error fetching pembelian:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (resultsPembelian.length === 0) {
      return res.status(404).json({ error: 'Transaksi pembelian not found' });
    }

    const pembelian = resultsPembelian[0];

    db.query(queryDetail, [id], (err, detailResults) => {
      if (err) {
        console.error('Error fetching detail:', err);
        return res.status(500).json({ error: 'Database error' });
      }

      pembelian.detail = detailResults;
      res.json(pembelian);
    });
  });
});

// POST tambah transaksi pembelian (dengan detail)
router.post('/', (req, res) => {
  const {
    no_faktur,
    penjual_id,
    product_id,
    total,
    items // array dari pembelian_detail
  } = req.body;

  // LOG request untuk debugging
  console.log('Received POST /pembelian with data:', {
    no_faktur,
    penjual_id,
    product_id,
    total,
    items_count: items ? items.length : 0
  });

  db.beginTransaction((err) => {
    if (err) {
      console.error('Error starting transaction:', err);
      return res.status(500).json({ error: 'Database error - transaction failed' });
    }

    const queryPembelian = `
      INSERT INTO pembelian (faktur_pemb, penjual_id, product_id, total, created_at)
      VALUES (?, ?, ?, ?, NOW())
    `;

    const valuesPembelian = [no_faktur, penjual_id, product_id, total];

    console.log('Executing pembelian query:', queryPembelian);
    console.log('With values:', valuesPembelian);

    db.query(queryPembelian, valuesPembelian, (err, results) => {
      if (err) {
        console.error('Error creating pembelian:', err);
        return db.rollback(() => {
          res.status(500).json({ error: 'Database error - pembelian insert failed: ' + err.message });
        });
      }

      const pembelianId = results.insertId;
      console.log('Pembelian created with ID:', pembelianId);

      if (items && items.length > 0) {
        const queryDetail = `
          INSERT INTO pembelian_detail 
          (faktur_pemb, nama_kayu, kriteria, diameter, panjang, jumlah, volume, harga_beli, jumlah_harga_beli) 
          VALUES ?
        `;

        const valuesDetail = items.map(item => [
          no_faktur, // Menggunakan no_faktur bukan pembelianId
          item.nama_kayu || '',
          item.kriteria,
          item.diameter,
          item.panjang,
          item.jumlah,
          item.volume,
          item.harga_beli,
          item.jumlah_harga_beli
        ]);

        console.log('Executing detail query with values:', valuesDetail);

        db.query(queryDetail, [valuesDetail], (err) => {
          if (err) {
            console.error('Error creating pembelian_detail:', err);
            return db.rollback(() => {
              res.status(500).json({ error: 'Database error - detail insert failed: ' + err.message });
            });
          }

          db.commit((err) => {
            if (err) {
              console.error('Error committing transaction:', err);
              return db.rollback(() => {
                res.status(500).json({ error: 'Database error - commit failed: ' + err.message });
              });
            }

            res.status(201).json({
              message: 'Transaksi pembelian created successfully',
              id: pembelianId
            });
          });
        });
      } else {
        db.commit((err) => {
          if (err) {
            console.error('Error committing transaction:', err);
            return db.rollback(() => {
              res.status(500).json({ error: 'Database error - commit failed: ' + err.message });
            });
          }

          res.status(201).json({
            message: 'Transaksi pembelian created successfully',
            id: pembelianId
          });
        });
      }
    });
  });
});

// PUT update pembelian (hanya data utama, tidak termasuk detail)
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { penjual_id, product_id, total } = req.body;

  const query = `
    UPDATE pembelian 
    SET penjual_id = ?, product_id = ?, total = ? 
    WHERE id = ?
  `;

  db.query(query, [penjual_id, product_id, total, id], (err, results) => {
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

// DELETE transaksi pembelian (utama dan detail)
router.delete('/:id', (req, res) => {
  const { id } = req.params;

  db.beginTransaction((err) => {
    if (err) {
      console.error('Error starting transaction:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    const deleteDetail = 'DELETE FROM pembelian_detail WHERE faktur_pemb = ?';
    const deletePembelian = 'DELETE FROM pembelian WHERE id = ?';

    db.query(deleteDetail, [id], (err) => {
      if (err) {
        return db.rollback(() => {
          console.error('Error deleting detail:', err);
          res.status(500).json({ error: 'Database error' });
        });
      }

      db.query(deletePembelian, [id], (err, results) => {
        if (err) {
          return db.rollback(() => {
            console.error('Error deleting pembelian:', err);
            res.status(500).json({ error: 'Database error' });
          });
        }

        if (results.affectedRows === 0) {
          return db.rollback(() => {
            res.status(404).json({ error: 'Transaksi pembelian not found' });
          });
        }

        db.commit((err) => {
          if (err) {
            return db.rollback(() => {
              console.error('Error committing delete:', err);
              res.status(500).json({ error: 'Database error' });
            });
          }

          res.json({ message: 'Transaksi pembelian deleted successfully' });
        });
      });
    });
  });
});

module.exports = router;
