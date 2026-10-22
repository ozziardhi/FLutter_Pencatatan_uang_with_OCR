# Aplikasi Pencatatan Uang with OCR 💰📱

Aplikasi mobile berbasis Flutter untuk mencatat keuangan pribadi secara praktis, dilengkapi dengan fitur **OCR (Optical Character Recognition)** untuk memindai teks/struk transaksi secara otomatis serta penyimpanan lokal menggunakan **Hive**.

---

## 🔄 Alur Kerja Aplikasi (App Flow)

Alur kerja aplikasi ini dibagi menjadi beberapa tahapan utama, mulai dari inisialisasi data, manajemen state menggunakan Riverpod, hingga proses pemindaian OCR:

### 1. Inisialisasi Aplikasi (`main.dart`)
* Aplikasi dimulai dengan menginisialisasi binding Flutter dan mendaftarkan penyimpanan lokal **Hive**.
* Membuka kotak (*box*) penyimpanan data transaksi lokal agar data tetap persisten meskipun aplikasi ditutup.
* Membungkus root widget dengan `ProviderScope` dari **Riverpod** untuk mengelola state secara global di seluruh aplikasi.

### 2. Manajemen State & Logika Bisnis (`providers/transaction_provider.dart`)
* Menggunakan **StateNotifier** dan **StateNotifierProvider** dari Riverpod untuk mengatur daftar transaksi (`List<TransactionModel>`).
* **Fungsi Utama pada Provider:**
  * **Load/Init:** Mengambil data transaksi yang tersimpan di Hive saat aplikasi pertama kali dibuka.
  * **Insert/Add:** Menambahkan data transaksi baru ke dalam *state* sekaligus menyimpannya secara otomatis ke Hive (`_box.put`).
  * **Update:** Memperbarui data transaksi yang sudah ada berdasarkan ID.
  * **Delete / Undo (Urungkan):** Menghapus atau memulihkan data transaksi jika fitur *undo* ditekan.

### 3. Antarmuka Pengguna & Dasbor (`screens/dashboard_screen.dart`)
* Berfungsi sebagai halaman utama yang menampilkan ringkasan keuangan dan daftar riwayat transaksi.
* Menggunakan widget yang mendengarkan perubahan state dari `transactionProvider` secara *real-time*.
* Menyediakan tombol interaktif bagi pengguna untuk menambah data transaksi secara manual maupun melalui pemindaian OCR.

### 4. Fitur OCR & Layanan Pendukung (`services/` & `models/`)
* **Model Data (`models/transaction_model.dart`):** Struktur data transaksi yang terintegrasi dengan Hive menggunakan *adapter* (`transaction_model.g.dart`) untuk mempermudah proses *serialization* objek ke database lokal.
* **Fitur OCR (`google_mlkit_text_recognition` & `image_picker`):**
  1. Pengguna mengambil foto struk belanja atau catatan nominal menggunakan kamera/galeri.
  2. Google ML Kit memproses gambar tersebut untuk mengekstrak teks di dalamnya.
  3. Aplikasi membaca teks hasil ekstraksi untuk mendeteksi nominal angka atau keterangan transaksi secara otomatis ke dalam form input.

---

## 🛠️ Tech Stack
* **Framework:** Flutter
* **State Management:** Flutter Riverpod (`flutter_riverpod`)
* **Local Database:** Hive (`hive`, `hive_flutter`)
* **OCR & Image:** Google ML Kit Text Recognition & Image Picker
* **Export/Print:** PDF & Printing