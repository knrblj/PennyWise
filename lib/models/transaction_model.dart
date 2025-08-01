class TransactionModel {
  final String id;
  final String type;
  final String category;
  final double amount;
  final String note;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
  });

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  // Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: json['type'],
      category: json['category'],
      amount: json['amount'].toDouble(),
      note: json['note'],
      date: DateTime.parse(json['date']),
    );
  }
}
