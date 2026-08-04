import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: map['id'].toString(),
      title: map['title'].toString(),
      amount: double.tryParse(map['amount'].toString()) ?? 0.0,
      isIncome: map['isIncome'] as bool? ?? false,
      date: DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
    );
  }
}
