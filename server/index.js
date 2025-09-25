const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Debug middleware - tambahkan ini
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Import routes
const masterBeliRoutes = require('./routes/masterbeli');
const masterJualRoutes = require('./routes/masterjual');
const pembeliRoutes = require('./routes/pembeli');
const penjualRoutes = require('./routes/penjual');
const penjualanRoutes = require('./routes/penjualan');
const pembelianRoutes = require('./routes/pembelian');
const stokRoutes = require('./routes/stok');
const userRoutes = require('./routes/user');

// Debug: Pastikan routes terload
console.log('Loading routes...');

// Use routes dengan path yang benar
app.use('/api/harga-beli', masterBeliRoutes);
app.use('/api/harga-jual', masterJualRoutes);
app.use('/api/pembeli', pembeliRoutes);
app.use('/api/penjual', penjualRoutes);
app.use('/api/penjualan', penjualanRoutes);
app.use('/api/pembelian', pembelianRoutes);
app.use('/api/stok', stokRoutes);
app.use('/api/users', userRoutes);

// Test route
app.get('/api/test', (req, res) => {
  res.json({ message: 'Server is running!' });
});

// Debug: Test stok route langsung
app.get('/api/debug/stok', (req, res) => {
  res.json({ message: 'Debug stok route is working!' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Handle 404 - harus di paling akhir
app.use('*', (req, res) => {
  console.log('404 - Route not found:', req.originalUrl);
  res.status(404).json({ 
    error: 'Route not found',
    requestedUrl: req.originalUrl,
    availableRoutes: [
      '/api/test',
      '/api/stok',
      '/api/stok/nama-kayu',
      '/api/stok/test',
      '/api/debug/stok',
      '/api/pembelian',
      '/api/penjualan'
    ]
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  console.log(`Available routes:`);
  console.log(`- GET /api/test`);
  console.log(`- GET /api/stok`);
  console.log(`- GET /api/stok/nama-kayu`);
  console.log(`- GET /api/stok/test`);
  console.log(`- GET /api/debug/stok`);
});