import 'package:flutter/material.dart';

// Models
import '../models/customer_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../../suppliers/models/supplier_model.dart';

// Services
import '../../transactions/services/transaction_service.dart';
import '../../suppliers/controllers/supplier_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({required this.customer});

  @override
  _CustomerDetailsScreenState createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState
    extends State<CustomerDetailsScreen> {

  final TransactionService transactionService = TransactionService();
  final SupplierService supplierService = SupplierService();

  List<TransactionModel> transactions = [];
  List<Supplier> suppliers = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    transactions = await transactionService.getTransactions();
    suppliers = await supplierService.getSuppliers();
    setState(() {});
  }

  List<TransactionModel> get customerTx =>
      transactions.where((t) => t.customerId == widget.customer.id).toList();

  Map<String, List<TransactionModel>> groupBySupplier() {
    Map<String, List<TransactionModel>> map = {};
    for (var t in customerTx) {
      map.putIfAbsent(t.supplierId, () => []);
      map[t.supplierId]!.add(t);
    }
    return map;
  }

  String getSupplierName(String id) {
    return suppliers.firstWhere((s) => s.id == id).name;
  }

  double getTotal() {
    return customerTx.fold(0, (sum, t) => sum + (t.quantity * t.price));
  }

  double getPaid() {
    return customerTx.fold(0, (sum, t) => sum + t.paidAmount);
  }

  double getRemaining() {
    return getTotal() - getPaid();
  }

  int getSuppliersCount() {
    return groupBySupplier().keys.length;
  }
void deleteTransactionSelection(List<TransactionModel> list) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text("اختر العملية للحذف"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((tx) {
            return ListTile(
              title: Text(tx.categoryName),
              subtitle: Text("الكمية: ${tx.quantity}"),
              onTap: () {
                Navigator.pop(context);
                deleteTransaction(tx);
              },
            );
          }).toList(),
        ),
      );
    },
  );
}
  // 🔥 حذف
 Future<void> deleteTransaction(TransactionModel tx) async {

  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("تأكيد الحذف"),
      content: Text(
        "هل أنت متأكد من حذف هذه العملية؟\n\n"
        "الفئة: ${tx.categoryName}\n"
        "الكمية: ${tx.quantity}",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("حذف"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // 🔥 تحديث فوري بدون إعادة تحميل
  setState(() {
    transactions.removeWhere((t) => t.id == tx.id);
  });

  await transactionService.saveTransactions(transactions);
}
  // 🔥 اختيار الفئة للتعديل (كما هو)
  void editTransactionSelection(List<TransactionModel> list) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("اختر الفئة للتعديل"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: list.map((tx) {
              return ListTile(
                title: Text(tx.categoryName),
                subtitle: Text("الكمية: ${tx.quantity}"),
                onTap: () {
                  Navigator.pop(context);
                  editTransaction(tx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 🔥 التعديل (المعدل فقط)
  void editTransaction(TransactionModel tx) {

    TextEditingController qtyCtrl =
        TextEditingController(text: tx.quantity.toString());

    TextEditingController paidCtrl =
        TextEditingController(text: tx.paidAmount.toString());

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("تعديل"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("الفئة: ${tx.categoryName}"),

                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "الكمية"),
                ),

                TextField(
                  controller: paidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "التسديد"),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء"),
            ),

            ElevatedButton(
              onPressed: () async {

                double newQty = double.tryParse(qtyCtrl.text) ?? 0;
                double paid = double.tryParse(paidCtrl.text) ?? 0;

                if (newQty <= 0) return;

                final supplier =
                    suppliers.firstWhere((s) => s.id == tx.supplierId);

                final category = supplier.categories
                    .firstWhere((c) => c.name == tx.categoryName);

                // 🔥 نحسب المبيعات بدون العملية الحالية
double soldWithoutCurrent = transactions
    .where((t) =>
        t.id != tx.id &&
        t.supplierId == supplier.id &&
        t.categoryName == category.name)
    .fold(0, (sum, t) => sum + t.quantity);

// 🔥 المخزون الحقيقي المتبقي
double remaining = category.quantity - soldWithoutCurrent;

// 🔥 أقصى كمية مسموحة (بما فيها المرتجع)
double maxAllowed = remaining;

// 🔴 إذا المستخدم طلب أكثر من المتوفر
if (newQty > maxAllowed) {

  bool? takeAvailable = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("⚠️ الكمية غير كافية"),
      content: Text(
        "المتوفر فقط: $remaining\n"
        "هل تريد أخذها؟",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("نعم"),
        ),
      ],
    ),
  );

  if (takeAvailable != true) return;

  newQty = remaining;
}

                int index =
                    transactions.indexWhere((t) => t.id == tx.id);

                if (index == -1) return;

                setState(() {
                  transactions[index] = TransactionModel(
                    id: tx.id,
                    customerId: tx.customerId,
                    supplierId: tx.supplierId,
                    categoryName: tx.categoryName,
                    quantity: newQty,
                    price: tx.price,
                    paidAmount: paid,
                    type: tx.type,
                    date: tx.date,
                  );
                });

                await transactionService.saveTransactions(transactions);

                Navigator.pop(context, true);
              },
              child: Text("حفظ"),
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteAllSupplierTransactions(List<TransactionModel> list) async {

  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("حذف المقوت بالكامل"),
      content: Text(
        "هل أنت متأكد من حذف جميع العمليات لهذا الرعوي",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("حذف"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  setState(() {
    for (var tx in list) {
      transactions.removeWhere((t) => t.id == tx.id);
    }
  });

  await transactionService.saveTransactions(transactions);
}

  @override
  Widget build(BuildContext context) {

    var grouped = groupBySupplier();

    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.name)),

      body: Column(
        children: [

          Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildRow("عدد الرعيه", getSuppliersCount()),
                  buildRow("الإجمالي", getTotal()),
                  buildRow("المدفوع", getPaid()),
                  buildRow("المتبقي", getRemaining(), isImportant: true),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                children: grouped.entries.map((entry) {

                  String supplierName = getSupplierName(entry.key);
                  List<TransactionModel> list = entry.value;

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Text(
                                supplierName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () =>
                                        editTransactionSelection(list),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        deleteTransactionSelection(list),
                                  ),
                                   IconButton(
      icon: Icon(Icons.delete_forever, color: Colors.red),
      onPressed: () =>
          deleteAllSupplierTransactions(list),
    ),
                                ],
                              ),
                            ],
                          ),

                          Divider(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("الفئة"),
                              Text("الكمية"),
                              Text("السعر"),
                              Text("المدفوع"),
                              Text("الباقي"),
                            ],
                          ),

                          SizedBox(height: 8),

                          Column(
                            children: list.map((t) {

                              double total = t.quantity * t.price;
                              double remaining = total - t.paidAmount;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(t.categoryName),
                                  Text("${t.quantity}"),
                                  Text("${t.price}"),
                                  Text("${t.paidAmount}"),
                                  Text(
                                    "$remaining",
                                    style: TextStyle(
                                      color: remaining > 0
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRow(String title, dynamic value, {bool isImportant = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "$value",
            style: TextStyle(
              fontWeight: isImportant ? FontWeight.bold : null,
              color: isImportant ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}