const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Import routes
const masterBeliRoutes = require('./routes/masterbeli');
const masterJualRoutes = require('./routes/masterjual');
const pembeliRoutes = require('./routes/pembeli');
const penjualRoutes = require('./routes/penjual');
// const penjualanRoutes = require('./routes/penjualan');
// const pembelianRoutes = require('./routes/pembelian');

// Use routes dengan path yang benar
app.use('/api/harga-beli', masterBeliRoutes);
app.use('/api/harga-jual', masterJualRoutes);
app.use('/api/pembeli', pembeliRoutes);
app.use('/api/penjual', penjualRoutes);
// app.use('/api/penjualan', penjualanRoutes);
// app.use('/api/pembelian', pembelianRoutes);

// Test route
app.get('/api/test', (req, res) => {
  res.json({ message: 'Server is running!' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Handle 404 - harus di paling akhir
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});