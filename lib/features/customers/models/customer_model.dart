
import '../../transactions/models/transaction_model.dart';

class Customer {
  final String id;
  final String name;

  Customer({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
    );
  }
}

// =======================
// 🧠 حسابات الزبون
// =======================
class CustomerCalculationService {
  Map<String, dynamic> calculate(
    String customerId,
    List<TransactionModel> transactions,
  ) {
    Map<String, dynamic> suppliers = {};

    double totalQty = 0;
    double totalAmount = 0;
    double totalPaid = 0;

    for (var t in transactions) {
      if (t.customerId != customerId) continue;

      String supplierKey = t.supplierId;

      if (!suppliers.containsKey(supplierKey)) {
        suppliers[supplierKey] = {
          "supplierId": t.supplierId,
          "totalQty": 0.0,
          "totalAmount": 0.0,
          "paid": 0.0,
          "categories": {},
        };
      }

      var supplier = suppliers[supplierKey];

      String catKey = t.categoryName;

      if (!supplier["categories"].containsKey(catKey)) {
        supplier["categories"][catKey] = {
          "category": catKey,
          "quantity": 0.0,
          "price": t.price,
          "total": 0.0,
          "paid": 0.0,
        };
      }

      var cat = supplier["categories"][catKey];

      if (t.type == TransactionType.sale) {
        double amount = t.quantity * t.price;

        cat["quantity"] += t.quantity;
        cat["total"] += amount;
        cat["paid"] += t.paidAmount;

        supplier["totalQty"] += t.quantity;
        supplier["totalAmount"] += amount;
        supplier["paid"] += t.paidAmount;

        totalQty += t.quantity;
        totalAmount += amount;
        totalPaid += t.paidAmount;
      }

      if (t.type == TransactionType.payment) {
        supplier["paid"] += t.paidAmount;
        totalPaid += t.paidAmount;
      }
    }

    suppliers.forEach((key, supplier) {
      supplier["remaining"] =
          supplier["totalAmount"] - supplier["paid"];

      supplier["categories"].forEach((k, cat) {
        cat["remaining"] = cat["total"] - cat["paid"];
      });

      supplier["categories"] =
          supplier["categories"].values.toList();
    });

    return {
      "totalSuppliers": suppliers.length,
      "totalQty": totalQty,
      "totalAmount": totalAmount,
      "totalPaid": totalPaid,
      "totalRemaining": totalAmount - totalPaid,
      "suppliers": suppliers.values.toList(),
    };
  }
}

