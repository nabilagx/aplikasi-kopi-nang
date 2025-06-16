<p align="center">
  <img src="assets/images/logo.png" alt="KOPI NANG Logo" width="180">
</p>

<h1 align="center">KOPI NANG ☕</h1>
<p align="center"><i>Aplikasi Pemesanan Kopi Berbasis Lokasi dan Verifikasi Visual</i></p>

<p align="center">
  Flutter • ASP.NET Core • PostgreSQL • Firebase • Midtrans
</p>

---

## 📱 Tentang Aplikasi

**KOPI NANG** adalah aplikasi pemesanan kopi berbasis lokasi yang memadukan teknologi dan kemudahan dalam satu genggaman. Pengguna dapat memesan kopi favorit, membayar secara digital, dan mengambil pesanan dengan QR code tanpa ribet. Admin pun dimudahkan dalam mengelola operasional harian lewat dashboard modern.

---

## 🎯 Fitur Aplikasi

### 👤 Pelanggan (Customer)
- 🔐 Login menggunakan Google (Firebase Auth)
- 🛍️ Lihat dan pilih menu kopi
- 🗺️ Menemukan kedai berdasarkan lokasi
- ➕ Tambahkan ke keranjang & atur jumlah
- 🎁 Menggunakan promo (dari Firebase)
- 💳 Pembayaran QRIS (Midtrans Snap API)
- 📥 Melihat riwayat pesanan & statusnya
- 🧾 Melihat struk pesanan (berbentuk tiket, dengan QR dan logo)
- ⭐ Memberi ulasan produk setelah pesanan selesai
- 📝 Melihat & menulis ulasan dengan rating dan komentar
- 🔐 Logout aman

### 🛠️ Admin
- 🔐 Login (Firebase)
- 📦 Melihat daftar pesanan masuk
- 🧾 Scan QR code dari pelanggan untuk verifikasi & menyelesaikan pesanan
- 📊 Dashboard Admin:
    - 🧾 Daftar pesanan terbaru
    - 💰 Total pemasukan hari ini
- 🎁 Kelola promo (Firebase Firestore)
- 💬 Melihat ulasan & membalas komentar pelanggan
- 📂 Ekspor data transaksi (opsional)

---

## 🛠️ Teknologi yang Digunakan

| Layer        | Teknologi                     |
|--------------|-------------------------------|
| Frontend     | Flutter (Mobile & Web)        |
| Backend      | ASP.NET Core Web API          |
| Database     | PostgreSQL (Railway)          |
| Auth         | Firebase Authentication       |
| Promo Data   | Firebase Firestore            |
| Pembayaran   | Midtrans Snap API (QRIS)      |
| Deployment   | Railway (API & DB)            |

---

## 🚀 Setup Cepat

### 📦 Backend (.NET)
```bash
cd kopinang-api
dotnet restore
dotnet run
```

### 📱 Flutter (Mobile)
```bash
flutter pub get
flutter run
```

### ⚙️ Konfigurasi Penting

* Buat project Firebase:
    * Aktifkan Auth Google
    * Buat koleksi Firestore: `promo`
* Buat akun Midtrans (sandbox), dapatkan `SERVER_KEY`
* Sesuaikan konfigurasi API di Flutter & ASP.NET

---

## 👨‍👩‍👧‍👦 KELOMPOK B07 – Pemrograman Berbasis Mobile

| Nama                | NIM          | Peran                      |
|---------------------|--------------|----------------------------|
| Nabila Choirunisa   | 232410102059 | Project Manager            |
| Fahmi Son Aji       | 232410102060 | System Analyst             |
| Farhat Auliya Hasan | 232410102094 | Tester                     |

---

## 📄 Lisensi

Aplikasi ini dikembangkan sebagai tugas akhir **mata kuliah Pemrograman Berbasis Mobile 2025**. Seluruh kode sumber dapat digunakan untuk keperluan pembelajaran dengan mencantumkan atribusi kepada tim pengembang asli.

---

<p align="center">
  Made with ☕ & 💻 by <b>Tim KOPI NANG</b> — “Nikmati Kopi, Rasakan Teknologi”
</p>
