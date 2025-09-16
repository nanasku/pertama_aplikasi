const express = require('express');
const router = express.Router();
const db = require('../db');
const moment = require('moment');

// Endpoint untuk mendapatkan nomor faktur penjualan baru
router.get('/noFakturBaru', (req, res) => {
  const query = "SELECT faktur_penj FROM penjualan ORDER BY id DESC LIMIT 1";
  db.query(query, (err, results) => {
    if (err) {
      console.error("Error fetch last faktur:", err);
      return res.status(500).json({ error: "Database error" });
    }

    let newFaktur;
    const today = moment().format('DDMMYYYY');

    if (results.length === 0) {
      newFaktur = `PJ-${today}-0001`;
    } else {
      const last = results[0].faktur_penj;
      const parts = last.split('-');

      if (parts.length !== 3) {
        newFaktur = `PJ-${today}-0001`;
      } else {
        const datePart = parts[1];
        const seqPart = parts[2];

        let newSeq;
        if (datePart === today) {
          newSeq = String(parseInt(seqPart, 10) + 1).padStart(4, '0');
        } else {
          newSeq = "0001";
        }

        newFaktur = `PJ-${today}-${newSeq}`;
      }
    }

    res.json({ faktur_penj: newFaktur });
  });
});

// GET semua transaksi penjualan
router.get('/', (req, res) => {
  const query = `
    SELECT 
      pj.* 
    FROM penjualan pj
    ORDER BY pj.created_at DESC
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    res.json(results);
  });
});

// GET penjualan by ID (beserta detail)
router.get('/:id', (req, res) => {
  const { id } = req.params;

  const queryPenjualan = `
    SELECT * FROM penjualan WHERE id = ?
  `;

  db.query(queryPenjualan, [id], (err, resultsPenjualan) => {
    if (err) {
      console.error('Error fetching penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (resultsPenjualan.length === 0) {
      return res.status(404).json({ error: 'Transaksi penjualan not found' });
    }

    const penjualan = resultsPenjualan[0];

    const queryDetail = `SELECT * FROM penjualan_detail WHERE faktur_penj = ?`;

    db.query(queryDetail, [penjualan.faktur_penj], (err, detailResults) => {
      if (err) {
        console.error('Error fetching detail:', err);
        return res.status(500).json({ error: 'Database error' });
      }

      penjualan.detail = detailResults;
      res.json(penjualan);
    });
  });
});

// POST tambah transaksi penjualan (dengan detail)
router.post('/', (req, res) => {
  const {
    faktur_penj,
    pembeli_id,
    alamat,
    telepon,
    email,
    product_id,
    total,
    items // array dari penjualan_detail
  } = req.body;

  console.log('Received POST /penjualan with data:', {
    faktur_penj,
    pembeli_id,
    alamat,
    telepon,
    email,
    product_id,
    total,
    items_count: items ? items.length : 0
  });

  db.beginTransaction((err) => {
    if (err) {
      console.error('Error starting transaction:', err);
      return res.status(500).json({ error: 'Database error - transaction failed' });
    }

    const queryPenjualan = `
      INSERT INTO penjualan 
      (faktur_penj, pembeli_id, alamat, telepon, email, product_id, total, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    `;

    const valuesPenjualan = [faktur_penj, pembeli_id, alamat, telepon, email, product_id, total];

    db.query(queryPenjualan, valuesPenjualan, (err, results) => {
      if (err) {
        console.error('Error creating penjualan:', err);
        return db.rollback(() => {
          res.status(500).json({ error: 'Database error - penjualan insert failed: ' + err.message });
        });
      }

      const penjualanId = results.insertId;

      if (items && items.length > 0) {
        const queryDetail = `
          INSERT INTO penjualan_detail 
          (faktur_penj, nama_kayu, kriteria, diameter, panjang, jumlah, volume, harga_jual, jumlah_harga_jual) 
          VALUES ?
        `;

        const valuesDetail = items.map(item => [
          faktur_penj,
          item.nama_kayu || '',
          item.kriteria,
          item.diameter,
          item.panjang,
          item.jumlah,
          item.volume,
          item.harga_jual,
          item.jumlah_harga_jual
        ]);

        db.query(queryDetail, [valuesDetail], (err) => {
          if (err) {
            console.error('Error creating penjualan_detail:', err);
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
              message: 'Transaksi penjualan created successfully',
              id: penjualanId
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
            message: 'Transaksi penjualan created successfully',
            id: penjualanId
          });
        });
      }
    });
  });
});

// PUT update penjualan (hanya data utama, tidak termasuk detail)
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { pembeli_id, alamat, telepon, email, product_id, total } = req.body;

  const query = `
    UPDATE penjualan 
    SET pembeli_id = ?, alamat = ?, telepon = ?, email = ?, product_id = ?, total = ? 
    WHERE id = ?
  `;

  db.query(query, [pembeli_id, alamat, telepon, email, product_id, total, id], (err, results) => {
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

// DELETE transaksi penjualan (utama dan detail)
router.delete('/:id', (req, res) => {
  const { id } = req.params;

  db.beginTransaction((err) => {
    if (err) {
      console.error('Error starting transaction:', err);
      return res.status(500).json({ error: 'Database error - start transaction' });
    }

    const getFakturQuery = 'SELECT faktur_penj FROM penjualan WHERE id = ?';

    db.query(getFakturQuery, [id], (err, result) => {
      if (err) {
        return db.rollback(() => {
          console.error('Error fetching faktur_penj:', err);
          res.status(500).json({ error: 'Database error - fetch faktur' });
        });
      }

      if (result.length === 0) {
        return db.rollback(() => {
          res.status(404).json({ error: 'Transaksi penjualan tidak ditemukan' });
        });
      }

      const faktur_penj = result[0].faktur_penj;

      const deleteDetailQuery = 'DELETE FROM penjualan_detail WHERE faktur_penj = ?';

      db.query(deleteDetailQuery, [faktur_penj], (err) => {
        if (err) {
          return db.rollback(() => {
            console.error('Error deleting penjualan_detail:', err);
            res.status(500).json({ error: 'Database error - delete detail' });
          });
        }

        const deletePenjualanQuery = 'DELETE FROM penjualan WHERE id = ?';

        db.query(deletePenjualanQuery, [id], (err, result) => {
          if (err) {
            return db.rollback(() => {
              console.error('Error deleting penjualan:', err);
              res.status(500).json({ error: 'Database error - delete penjualan' });
            });
          }

          if (result.affectedRows === 0) {
            return db.rollback(() => {
              res.status(404).json({ error: 'Transaksi penjualan tidak ditemukan saat delete' });
            });
          }

          db.commit((err) => {
            if (err) {
              return db.rollback(() => {
                console.error('Error committing transaction:', err);
                res.status(500).json({ error: 'Database error - commit' });
              });
            }

            res.json({ message: 'Transaksi penjualan berhasil dihapus' });
          });
        });
      });
    });
  });
});

module.exports = router;
