# 📑 Catat Keuangan with OCR & Hive Storage

Aplikasi pencatatan keuangan pribadi berbasis **Flutter** yang dilengkapi fitur pengenal nota otomatis (**OCR**), ekspor laporan **PDF**, serta penyimpanan lokal permanen menggunakan **Hive**.

---

## 🔄 Alur Kerja Aplikasi (Workflow)

```text
[ User Interface (DashboardScreen) ]
             │
             ├──► 1. Input Transaksi Manual / OCR (Image Picker -> OcrService)
             │
             ├──► 2. Kirim Data / Aksi State (Riverpod: TransactionNotifier)
             │
             ├──► 3. Simpan & Olah Data Lokal (Hive Box: 'transactions_box')
             │
             └──► 4. Ekspor Laporan (PdfService -> Printing Package)