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
  const { tanggal, bulan, pembeli_id } = req.query;

  let conditions = [];
  let values = [];

  if (tanggal) {
    conditions.push('DATE(pb.created_at) = ?');
    values.push(tanggal); // Format: 'YYYY-MM-DD'
  }

  if (bulan) {
    conditions.push('DATE_FORMAT(pb.created_at, "%Y-%m") = ?');
    values.push(bulan); // Format: 'YYYY-MM'
  }

  if (pembeli_id) {
    conditions.push('pb.pembeli_id = ?');
    values.push(pembeli_id);
  }

  let whereClause = '';
  if (conditions.length > 0) {
    whereClause = 'WHERE ' + conditions.join(' AND ');
  }

  // PERBAIKAN: Tambahkan whereClause dan values ke query
  const query = `
    SELECT 
      pb.*, 
      pl.nama AS nama_pembeli, 
      h.nama_kayu AS nama_barang
    FROM penjualan pb
    LEFT JOIN pembeli pl ON pb.pembeli_id = pl.id
    LEFT JOIN harga_jual h ON pb.product_id = h.id
    ${whereClause}
    ORDER BY pb.created_at DESC
  `;

  console.log('Executing query:', query); // Debugging
  console.log('With values:', values); // Debugging

  db.query(query, values, (err, results) => { // PERBAIKAN: Tambahkan values
    if (err) {
      console.error('Error fetching penjualan:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    res.json(results);
  });
});

// GET penjualan by ID (beserta detail) - PERBAIKAN
router.get('/:id', (req, res) => {
  const { id } = req.params;

  const queryPenjualan = `
    SELECT 
      pj.*, 
      pl.nama AS nama_pembeli, 
      h.nama_kayu AS nama_barang
    FROM penjualan pj
    LEFT JOIN pembeli pl ON pj.pembeli_id = pl.id
    LEFT JOIN harga_jual h ON pj.product_id = h.id
    WHERE pj.id = ?
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
    const faktur_penj = penjualan.faktur_penj; // Ambil faktur_pemb dari hasil query

    const queryDetail = `
      SELECT * FROM penjualan_detail WHERE faktur_penj = ?
    `;

    db.query(queryDetail, [faktur_penj], (err, detailResults) => {
      if (err) {
        console.error('Error fetching detail:', err);
        return res.status(500).json({ error: 'Database error' });
      }

      penjualan.detail = detailResults;
      res.json(penjualan);
    });
  });
});

// POST tambah transaksi pembelian (VERSION FIXED)
router.post('/', (req, res) => {
  const {
    faktur_penj,
    pembeli_id,
    product_id,
    total,
    items,
    operasionals
  } = req.body;

  console.log('Received POST /penjualan with data:', {
    faktur_penj,
    pembeli_id,
    product_id,
    total: total,
    total_type: typeof total,
    items_count: items ? items.length : 0,
    operasional_count: operasionals ? operasionals.length : 0
  });

  db.beginTransaction((err) => {
    if (err) {
      console.error('Error starting transaction:', err);
      return res.status(500).json({ error: 'Database error - transaction failed' });
    }

    // 1. Insert data utama pembelian dengan total sementara
    const queryPenjualan = `
      INSERT INTO penjualan (faktur_penj, pembeli_id, product_id, total, created_at)
      VALUES (?, ?, ?, ?, NOW())
    `;
    // Konversi ke number untuk memastikan
    const initialTotal = Number(total) || 0;
    const valuesPenjualan = [faktur_penj, pembeli_id, product_id, initialTotal];

    db.query(queryPenjualan, valuesPenjualan, (err, results) => {
      if (err) {
        console.error('Error creating penjualan:', err);
        return db.rollback(() => {
          res.status(500).json({ error: 'Database error - penjualan insert failed: ' + err.message });
        });
      }

      const penjualanId = results.insertId;

      // 2. Insert detail pembelian
      const insertDetail = (cb) => {
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
              return cb(err);
            }
            cb(null);
          });
        } else {
          cb(null);
        }
      };

      // 3. Insert operasional
      const insertOperasional = (cb) => {
        if (operasionals && operasionals.length > 0) {
          const queryOps = `
            INSERT INTO penjualan_operasional (faktur_penj, jenis, biaya, tipe)
            VALUES ?
          `;
          const valuesOps = operasionals.map(op => [
            faktur_penj,
            op.jenis || '',
            Number(op.biaya) || 0, // Pastikan number
            op.tipe
          ]);

          db.query(queryOps, [valuesOps], (err) => {
            if (err) {
              return cb(err);
            }
            cb(null);
          });
        } else {
          cb(null);
        }
      };

      // 4. FUNGSI PERBAIKAN: Kalkulasi ulang total dengan konversi number
      const recalculateTotal = (cb) => {
        const queryRecalc = `
          SELECT 
            COALESCE(SUM(pd.jumlah_harga_jual), 0) as total_items,
            COALESCE(SUM(
              CASE 
                WHEN po.tipe = 'tambah' THEN po.biaya 
                ELSE -po.biaya 
              END
            ), 0) as total_ops
          FROM penjualan_detail pd
          LEFT JOIN penjualan_operasional po ON pd.faktur_penj = po.faktur_penj
          WHERE pd.faktur_penj = ?
        `;

        db.query(queryRecalc, [faktur_penj], (err, results) => {
          if (err) return cb(err);
          
          // PERBAIKAN: Konversi eksplisit ke Number
          const totalItems = Number(results[0]?.total_items) || 0;
          const totalOps = Number(results[0]?.total_ops) || 0;
          const finalTotal = totalItems + totalOps;

          console.log('=== RECALCULATION DEBUG ===');
          console.log('Total Items:', totalItems, 'Type:', typeof totalItems);
          console.log('Total Ops:', totalOps, 'Type:', typeof totalOps);
          console.log('Final Total:', finalTotal, 'Type:', typeof finalTotal);
          console.log('Expected: 164000 + 2500 = 166500');

          // Update total di pembelian
          const updateQuery = `UPDATE penjualan SET total = ? WHERE faktur_penj = ?`;
          db.query(updateQuery, [finalTotal, faktur_penj], (err) => {
            if (err) return cb(err);
            cb(null, finalTotal);
          });
        });
      };

      // Jalankan proses berurutan
      insertDetail((err) => {
        if (err) {
          return db.rollback(() => {
            res.status(500).json({ error: 'Database error - detail insert failed: ' + err.message });
          });
        }

        insertOperasional((err) => {
          if (err) {
            return db.rollback(() => {
              res.status(500).json({ error: 'Database error - operasional insert failed: ' + err.message });
            });
          }

          recalculateTotal((err, finalTotal) => {
            if (err) {
              return db.rollback(() => {
                res.status(500).json({ error: 'Database error - recalculate total failed: ' + err.message });
              });
            }

            db.commit((err) => {
              if (err) {
                return db.rollback(() => {
                  res.status(500).json({ error: 'Database error - commit failed: ' + err.message });
                });
              }

              console.log('Transaction completed successfully. Final total:', finalTotal);
              res.status(201).json({
                message: 'Transaksi penjualan created successfully',
                id: penjualanId,
                final_total: finalTotal
              });
            });
          });
        });
      });
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
