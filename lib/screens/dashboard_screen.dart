import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF004D40),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catat Keuangan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.teal.shade100,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 4.0),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.add,
                    tooltip: 'Tambah Transaksi',
                    onPressed: () => _showAddTransactionModal(context, ref),
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: Icons.picture_as_pdf_outlined,
                    tooltip: 'Export PDF',
                    onPressed: () {
                      if (transactions.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Belum ada data untuk diexport!'),
                          ),
                        );
                      } else {
                        PdfService.generateAndPrintPdf(transactions);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Card Ringkasan Saldo
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00796B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Sisa Saldo',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dana Masuk',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          currencyFormat.format(totalIncome),
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Dana Keluar',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          currencyFormat.format(totalExpense),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Transaksi (Geser kiri untuk hapus)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // List Riwayat
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          final deletedItem = item;
                          final deletedIndex = index;

                          ref
                              .read(transactionProvider.notifier)
                              .deleteTransaction(item.id);

                          final messenger = ScaffoldMessenger.of(context);
                          messenger.clearSnackBars();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('"${deletedItem.title}" terhapus'),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'URUNGKAN',
                                textColor: Colors.amber,
                                onPressed: () {
                                  ref
                                      .read(transactionProvider.notifier)
                                      .insertTransaction(
                                        deletedIndex,
                                        deletedItem,
                                      );
                                },
                              ),
                            ),
                          );

                          // Pemaksaan tutup SnackBar di detik ke-3
                          Future.delayed(const Duration(seconds: 3), () {
                            messenger.hideCurrentSnackBar();
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () {
                              _showAddTransactionModal(
                                context,
                                ref,
                                transactionToEdit: item,
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: item.isIncome
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              child: Icon(
                                item.isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: item.isIncome
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(item.date),
                            ),
                            trailing: Text(
                              '${item.isIncome ? '+' : '-'} ${currencyFormat.format(item.amount)}',
                              style: TextStyle(
                                color: item.isIncome
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  void _showAddTransactionModal(
    BuildContext context,
    WidgetRef ref, {
    TransactionModel? transactionToEdit,
  }) {
    final isEditing = transactionToEdit != null;

    final titleController = TextEditingController(
      text: isEditing ? transactionToEdit.title : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? transactionToEdit.amount.toInt().toString() : '',
    );
    bool isIncome = isEditing ? transactionToEdit.isIncome : false;
    final ocrService = OcrService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> scanReceipt(ImageSource source) async {
              final image = await ocrService.pickImage(source);
              if (image != null) {
                final amount = await ocrService.processImageToAmount(image);
                if (amount != null) {
                  setModalState(() {
                    amountController.text = amount.toInt().toString();
                    if (titleController.text.isEmpty) {
                      titleController.text = 'Pembelian Nota';
                    }
                  });
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Transaksi' : 'Tambah Transaksi',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isEditing)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.teal,
                                ),
                                onPressed: () =>
                                    scanReceipt(ImageSource.camera),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.photo_library,
                                  color: Colors.teal,
                                ),
                                onPressed: () =>
                                    scanReceipt(ImageSource.gallery),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                      ),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Uang (Rp)',
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Dana Masuk')),
                            selected: isIncome,
                            onSelected: (selected) {
                              setModalState(() => isIncome = true);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Dana Keluar')),
                            selected: !isIncome,
                            onSelected: (selected) {
                              setModalState(() => isIncome = false);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final amount =
                              double.tryParse(amountController.text) ?? 0;

                          if (title.isNotEmpty && amount > 0) {
                            if (isEditing) {
                              ref
                                  .read(transactionProvider.notifier)
                                  .updateTransaction(
                                    TransactionModel(
                                      id: transactionToEdit.id,
                                      title: title,
                                      amount: amount,
                                      isIncome: isIncome,
                                      date: transactionToEdit.date,
                                    ),
                                  );
                            } else {
                              ref
                                  .read(transactionProvider.notifier)
                                  .addTransaction(
                                    TransactionModel(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      title: title,
                                      amount: amount,
                                      isIncome: isIncome,
                                      date: DateTime.now(),
                                    ),
                                  );
                            }
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(isEditing ? 'Perbarui' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
