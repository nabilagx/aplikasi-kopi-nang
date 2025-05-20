const express = require('express');
const multer = require('multer');
const cors = require('cors');
const { v2: cloudinary } = require('cloudinary');
const { CloudinaryStorage } = require('multer-storage-cloudinary');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());

// Konfigurasi Cloudinary (ganti dengan milikmu)
cloudinary.config({
  cloud_name: 'YOUR_CLOUD_NAME',
  api_key: 'YOUR_API_KEY',
  api_secret: 'YOUR_API_SECRET',
});

// Storage Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'kopi_nang_produk',
    allowed_formats: ['jpg', 'png'],
  },
});
const upload = multer({ storage });

// Endpoint upload gambar
app.post('/upload', upload.single('file'), (req, res) => {
  res.send(req.file.path); // URL Cloudinary
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
