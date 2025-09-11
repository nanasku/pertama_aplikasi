const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config(); // Load .env

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/penjual', require('./routes/penjual'));
app.use('/pembeli', require('./routes/pembeli'));
app.use('/masterjual', require('./routes/masterjual'));
app.use('/masterbeli', require('./routes/masterbeli'));
app.use('/penjualan', require('./routes/penjualan'));
app.use('/pembelian', require('./routes/pembelian'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});