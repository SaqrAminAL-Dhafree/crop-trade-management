
import '../../transactions/models/transaction_model.dart';

class Supplier {
  final String id;
  final String name;
  final List<Category> categories;

  // 🔥 الجديد
  final double receivedAmount;

  Supplier({
    required this.id,
    required this.name,
    required this.categories,
    required this.receivedAmount, // 🔥
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categories': categories.map((e) => e.toJson()).toList(),

        // 🔥 الجديد
        'receivedAmount': receivedAmount,
      };

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      categories: (json['categories'] as List)
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      // 🔥 مهم جدًا (عشان ما ينهار التطبيق)
      receivedAmount: (json['receivedAmount'] ?? 0).toDouble(),
    );
  }
}
// =======================
class Category {
  final String name;
  final double price;
  final double quantity;

  Category({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
    );
  }
}

// =======================
// 🧠 حسابات المقوّت
// =======================
class SupplierCalculationService {
  Map<String, dynamic> calculate(
    Supplier supplier,
    List<TransactionModel> transactions,
  ) {
    double totalQty = 0;
    double totalValue = 0;

    Map<String, dynamic> categories = {};
    Map<String, dynamic> customers = {};

    for (var cat in supplier.categories) {
      totalQty += cat.quantity;
      totalValue += cat.total;

      categories[cat.name] = {
        "price": cat.price,
        "originalQty": cat.quantity,
        "soldQty": 0.0,
        "remainingQty": cat.quantity,
        "totalValue": cat.total,
      };
    }

    double totalSold = 0;
    double totalPaid = 0;

    for (var t in transactions) {
      if (t.supplierId != supplier.id) continue;

      if (t.type == TransactionType.sale) {
        double amount = t.quantity * t.price;

        categories[t.categoryName]["soldQty"] += t.quantity;
        categories[t.categoryName]["remainingQty"] -= t.quantity;

        totalSold += amount;
        totalPaid += t.paidAmount;

        String key = "${t.customerId}_${t.categoryName}";

        if (!customers.containsKey(key)) {
          customers[key] = {
            "customerId": t.customerId,
            "category": t.categoryName,
            "quantity": 0.0,
            "total": 0.0,
            "paid": 0.0,
          };
        }

        customers[key]["quantity"] += t.quantity;
        customers[key]["total"] += amount;
        customers[key]["paid"] += t.paidAmount;
      }

      if (t.type == TransactionType.payment) {
        totalPaid += t.paidAmount;
      }
    }

    return {
      "totalQty": totalQty,
      "totalValue": totalValue,
      "totalSold": totalSold,
      "totalPaid": totalPaid,
      "remainingMoney": totalSold - totalPaid,
      "categories": categories,
      "customers": customers.values.toList(),
    };
  }
}

