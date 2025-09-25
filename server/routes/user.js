const express = require('express');
const router = express.Router();
const db = require('../db');
const multer = require('multer');
const path = require('path');

// Konfigurasi upload file
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/profiles/');
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// Get user profile
router.get('/profile/:id', (req, res) => {
  console.log('Fetching user profile for ID:', req.params.id);

  db.execute(
    'SELECT id, username, email, company_name, profile_image FROM users WHERE id = ?',
    [req.params.id],
    (err, results) => {
      if (err) {
        console.error('Error fetching user:', err);
        return res.status(500).json({ message: 'Server error', error: err.message });
      }

      if (results.length === 0) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
      }

      console.log('User data:', results[0]);
      res.json(results[0]);
    }
  );
});

// Update user profile
router.put('/profile/:id', upload.single('profile_image'), (req, res) => {
  const { username, email, company_name } = req.body;
  let profileImage = null;

  if (req.file) {
    profileImage = req.file.filename;
  }

  let query = 'UPDATE users SET username = ?, email = ?, company_name = ?';
  let params = [username, email, company_name];

  if (profileImage) {
    query += ', profile_image = ?';
    params.push(profileImage);
  }

  query += ' WHERE id = ?';
  params.push(req.params.id);

  db.execute(query, params, (err, result) => {
    if (err) {
      console.error('Error updating user:', err);
      return res.status(500).json({ message: 'Server error', error: err.message });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    res.json({ message: 'Profil berhasil diperbarui' });
  });
});


module.exports = router;