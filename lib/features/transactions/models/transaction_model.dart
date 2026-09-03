
enum TransactionType { sale, payment }

class TransactionModel {
  final String id;
  final String customerId;
  final String supplierId;
  final String categoryName;

  final double quantity;
  final double price;
  final double paidAmount;

  final TransactionType type;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.customerId,
    required this.supplierId,
    required this.categoryName,
    required this.quantity,
    required this.price,
    required this.paidAmount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'supplierId': supplierId,
        'categoryName': categoryName,
        'quantity': quantity,
        'price': price,
        'paidAmount': paidAmount,
        'type': type.name,
        'date': date.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      customerId: json['customerId'],
      supplierId: json['supplierId'],
      categoryName: json['categoryName'],
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      type: TransactionType.values
          .firstWhere((e) => e.name == json['type']),
      date: DateTime.parse(json['date']),
    );
  }
}
