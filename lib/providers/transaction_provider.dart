import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final Box _box = Hive.box('transactions_box');

  TransactionNotifier() : super([]) {
    _loadTransactions();
  }

  // Load Data dari Hive
  void _loadTransactions() {
    try {
      final List<TransactionModel> loadedList = [];
      for (var key in _box.keys) {
        final rawData = _box.get(key);
        if (rawData != null && rawData is Map) {
          loadedList.add(TransactionModel.fromMap(rawData));
        }
      }
      loadedList.sort((a, b) => b.date.compareTo(a.date));
      state = loadedList;
    } catch (e) {
      print('Error loading Hive data: $e');
    }
  }

  // Tambah Transaksi
  void addTransaction(TransactionModel transaction) {
    state = [transaction, ...state];
    _box.put(transaction.id, transaction.toMap());
  }

  // Hapus Transaksi (Langsung Permanen dari Hive)
  void deleteTransaction(String id) {
    state = state.where((item) => item.id != id).toList();
    _box.delete(id);
  }

  // Restore Transaksi jika 'URUNGKAN' ditekan
  void insertTransaction(int index, TransactionModel item) {
    final updatedList = List<TransactionModel>.from(state);
    if (index <= updatedList.length) {
      updatedList.insert(index, item);
    } else {
      updatedList.add(item);
    }
    state = updatedList;
    _box.put(item.id, item.toMap());
  }

  // Edit/Update Transaksi
  void updateTransaction(TransactionModel updatedTransaction) {
    state = [
      for (final item in state)
        if (item.id == updatedTransaction.id) updatedTransaction else item,
    ];
    _box.put(updatedTransaction.id, updatedTransaction.toMap());
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
      return TransactionNotifier();
    });
