import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

class PdfService {
  static Future<void> generateAndPrintPdf(
    List<TransactionModel> transactions,
  ) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Hitung Ringkasan
    double totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);

    double totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);

    double totalBalance = totalIncome - totalExpense;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            // ✅ BENAR
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Laporan
              pw.Text(
                'Laporan Keuangan',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // Kartu Ringkasan
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStat(
                      'Dana Masuk',
                      currencyFormat.format(totalIncome),
                      PdfColors.green700,
                    ),
                    _buildPdfStat(
                      'Dana Keluar',
                      currencyFormat.format(totalExpense),
                      PdfColors.red700,
                    ),
                    _buildPdfStat(
                      'Sisa Saldo',
                      currencyFormat.format(totalBalance),
                      PdfColors.blue700,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabel Riwayat Transaksi
              pw.Text(
                'Detail Transaksi',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['Tanggal', 'Keterangan', 'Tipe', 'Nominal'],
                data: transactions.map((item) {
                  return [
                    DateFormat('dd/MM/yyyy HH:mm').format(item.date),
                    item.title,
                    item.isIncome ? 'Pemasukan' : 'Pengeluaran',
                    currencyFormat.format(item.amount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {3: pw.Alignment.centerRight},
              ),
            ],
          );
        },
      ),
    );

    // Buka Tampilan Print / Save PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Laporan_Keuangan_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildPdfStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
