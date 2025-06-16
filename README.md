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

**KOPI NANG** adalah aplikasi pemesanan kopi kekinian yang memadukan teknologi dengan cita rasa lokal. Dengan sistem berbasis lokasi dan verifikasi visual via QR code, pengguna dapat memesan kopi secara instan dan efisien, serta menikmati pengalaman pemesanan modern yang aman dan nyaman.

---

## 🎯 Fitur Utama

### Pelanggan
- 🔐 Login dengan Google (Firebase Auth)
- 📍 Temukan & pesan kopi dari lokasi terdekat
- 🎁 Gunakan promo aktif (masa berlaku & kuota)
- 💳 Pembayaran QRIS via Midtrans
- 🧾 Struk digital berbentuk tiket + QR code
- ⭐ Memberi ulasan produk

### Admin
- 📦 Kelola pesanan masuk
- 📊 Dashboard Web untuk monitoring pesanan & pendapatan
- ✅ Verifikasi QR untuk menyelesaikan pesanan
- 🔍 Lacak status dan pendapatan harian

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
