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

// Get user profile - PERBAIKI SYNTAX INI
router.get('/profile/:id', async (req, res) => {
    try {
        console.log('Fetching user profile for ID:', req.params.id); // Debug log
        const [rows] = await db.execute('SELECT id, username, email, company_name, profile_image FROM users WHERE id = ?', [req.params.id]);
        
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }
        
        console.log('User data:', rows[0]); // Debug log
        res.json(rows[0]);
    } catch (error) {
        console.error('Error fetching user:', error); // Debug log
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Update user profile - PERBAIKI SYNTAX INI
router.put('/profile/:id', upload.single('profile_image'), async (req, res) => {
    try {
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

        const [result] = await db.execute(query, params);
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }
        
        res.json({ message: 'Profil berhasil diperbarui' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;