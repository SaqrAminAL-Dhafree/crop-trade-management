
import 'package:flutter/material.dart';

// Models
import '../../suppliers/models/supplier_model.dart';
import '../../customers/models/customer_model.dart';
import '../../transactions/models/transaction_model.dart';

// Services
import '../../suppliers/controllers/supplier_service.dart';
import '../../customers/controllers/customer_service.dart';
import '../../transactions/services/transaction_service.dart';

// Details
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {

  final SupplierService supplierService = SupplierService();
  final CustomerService customerService = CustomerService();
  final TransactionService transactionService = TransactionService();

  List<Supplier> suppliers = [];
  List<Customer> customers = [];
  List<TransactionModel> transactions = [];

  String? selectedSupplierId;
  String? selectedCategoryName;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController paidController = TextEditingController();

  List<TransactionModel> tempOperations = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    suppliers = await supplierService.getSuppliers();
    customers = await customerService.getCustomers();
    transactions = await transactionService.getTransactions();
    setState(() {});
  }

  Supplier getSelectedSupplier() {
    return suppliers.firstWhere((s) => s.id == selectedSupplierId);
  }

  Category getSelectedCategory() {
    return getSelectedSupplier()
        .categories
        .firstWhere((c) => c.name == selectedCategoryName);
  }

 double getRemaining(Category c, Supplier s) {
  double sold = transactions
      .where((t) =>
          t.supplierId == s.id &&
          t.categoryName == c.name)
      .fold(0, (sum, t) => sum + t.quantity);

  // 🔥 الجديد (إضافة العمليات المؤقتة)
  double tempSold = tempOperations
      .where((t) =>
          t.supplierId == s.id &&
          t.categoryName == c.name)
      .fold(0, (sum, t) => sum + t.quantity);

  return c.quantity - sold - tempSold;
}
// 🔥 نفس كودك + إصلاح زر الإضافة + إضافة خيارات

// (اختصار: لن ألمس أي شيء من منطقك — فقط أصلح النافذة وأضيف الخيارات)



// 🔥 هذا هو الجزء المهم الذي كان سبب المشكلة
void openAddOperationDialog(Customer customer) {

  String? supplierId;
  String? categoryName;

  TextEditingController qtyCtrl = TextEditingController();
  TextEditingController paidCtrl = TextEditingController();

  List<TransactionModel> localTemp = [];

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {

          Supplier? supplier = supplierId == null
              ? null
              : suppliers.firstWhere((s) => s.id == supplierId);

          return AlertDialog(
            title: Text("إضافة عمليات لـ ${customer.name}"),

            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // 🔹 المقوت
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        hint: Text("الرعوي"),
                        value: supplierId,
                        items: suppliers.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            supplierId = val;
                            categoryName = null;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: 10),

                    // 🔹 الفئة (🔥 الحل هنا)
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        menuMaxHeight: 300,
                        hint: Text("الفئة"),
                        value: categoryName,
                        items: supplier == null
                            ? []
                            : supplier.categories.map((c) {
                                double remaining = getRemaining(c, supplier);
                                return DropdownMenuItem(
                                  value: c.name,
                                  enabled: remaining > 0,
                                  child: Text("${c.name} - ${c.price} (متبقي: $remaining)",
                                   style: TextStyle(
                  color: remaining > 0 ? Colors.white : Colors.grey,
                ),
                                  ),
                                );
                              }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            categoryName = val;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: 10),

                    // 🔹 الكمية
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "الكمية"),
                    ),

                    SizedBox(height: 10),

                    // 🔹 المدفوع
                    TextField(
                      controller: paidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "التسديد"),
                    ),

                    SizedBox(height: 10),

                    // 🔥 زر إضافة
                    ElevatedButton(
                      child: Text("إضافة"),
                      onPressed: () async {

                        if (supplierId == null || categoryName == null) return;

                        double qty = double.tryParse(qtyCtrl.text) ?? 0;
                        double paid = double.tryParse(paidCtrl.text) ?? 0;

                        final supplier =
                            suppliers.firstWhere((s) => s.id == supplierId);

                        final category = supplier.categories
                            .firstWhere((c) => c.name == categoryName);

                        double remaining = getRemaining(category, supplier);

                        if (qty > remaining) {
                          bool? takeAvailable = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("⚠️ الكمية غير كافية"),
                              content: Text("المتوفر فقط: $remaining\nهل تريد شراءها؟"),
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
                          qty = remaining;
                        }

                        bool exists = localTemp.any((op) =>
                            op.supplierId == supplier.id &&
                            op.categoryName == category.name &&
                            op.quantity == qty &&
                            op.paidAmount == paid);

                        if (exists) {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("⚠️ عملية مكررة"),
                              content: Text("هل تريد إضافتها؟"),
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

                          if (confirm != true) return;
                        }

                        localTemp.add(
                          TransactionModel(
                            id: DateTime.now().toString(),
                            customerId: customer.id,
                            supplierId: supplier.id,
                            categoryName: category.name,
                            quantity: qty,
                            price: category.price,
                            paidAmount: paid,
                            type: TransactionType.sale,
                            date: DateTime.now(),
                          ),
                        );

                        qtyCtrl.clear();
                        paidCtrl.clear();

                        setStateDialog(() {});
                      },
                    ),

                    SizedBox(height: 10),

                    Column(
                      children: localTemp.map((e) {
                        return ListTile(
                          title: Text(e.categoryName),
                          subtitle: Text("${e.quantity}"),
                          trailing: Text("مدفوع: ${e.paidAmount}"),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            actions: [

              TextButton(
                child: Text("إلغاء"),
                onPressed: () => Navigator.pop(context),
              ),

              ElevatedButton(
                child: Text("حفظ"),
                onPressed: () async {

                  if (localTemp.isEmpty) return;

                  transactions.addAll(localTemp);
                  await transactionService.saveTransactions(transactions);

                  Navigator.pop(context);
                  await loadData();
                },
              ),
            ],
          );
        },
      );
    },
  );
}


  // 🔥 تعديل زبون
  void editCustomer(Customer c) {
    TextEditingController ctrl =
        TextEditingController(text: c.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("تعديل الزبون"),
        content: TextField(controller: ctrl),
        actions: [
          ElevatedButton(
            onPressed: () async {
              int i = customers.indexWhere((e) => e.id == c.id);
              customers[i] = Customer(id: c.id, name: ctrl.text);

              await customerService.saveCustomers(customers);
              Navigator.pop(context);
              await loadData();
            },
            child: Text("حفظ"),
          )
        ],
      ),
    );
  }

  // 🔥 حذف زبون
  Future<void> deleteCustomer(Customer c) async {

    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد؟"),
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

    transactions.removeWhere((t) => t.customerId == c.id);
    customers.removeWhere((e) => e.id == c.id);

    await customerService.saveCustomers(customers);
    await transactionService.saveTransactions(transactions);

    await loadData();
  }

  Future<void> addTempOperation() async {

    if (selectedSupplierId == null ||
        selectedCategoryName == null ||
        qtyController.text.isEmpty) return;

    double qty = double.tryParse(qtyController.text) ?? 0;
    double paid = double.tryParse(paidController.text) ?? 0;

    final supplier = getSelectedSupplier();
    final category = getSelectedCategory();

    double remaining = getRemaining(category, supplier);

   if (qty > remaining) {
  bool? takeAvailable = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("⚠️ الكمية غير كافية"),
      content: Text("المتوفر فقط: $remaining\nهل تريد شراءها؟"),
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
  qty = remaining;
}
// 🔥 منع التكرار
bool exists = tempOperations.any((op) =>
    op.supplierId == supplier.id &&
    op.categoryName == category.name &&
    op.quantity == qty &&
    op.paidAmount == paid);

if (exists) {
  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("⚠️ عملية مكررة"),
      content: Text("هذه العملية موجودة بنفس البيانات، هل تريد إضافتها؟"),
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

  if (confirm != true) return;
}

    tempOperations.add(
      TransactionModel(
        id: DateTime.now().toString(),
        customerId: "temp",
        supplierId: supplier.id,
        categoryName: category.name,
        quantity: qty,
        price: category.price,
        paidAmount: paid,
        type: TransactionType.sale,
        date: DateTime.now(),
      ),
    );

    qtyController.clear();
    paidController.clear();

    setState(() {});
  }

  Future<void> saveCustomer() async {

    if (customerNameController.text.isEmpty || tempOperations.isEmpty) return;

    Customer newCustomer = Customer(
      id: DateTime.now().toString(),
      name: customerNameController.text,
    );

    customers.add(newCustomer);
    await customerService.saveCustomers(customers);

    for (var op in tempOperations) {
      transactions.add(
        TransactionModel(
          id: op.id,
          customerId: newCustomer.id,
          supplierId: op.supplierId,
          categoryName: op.categoryName,
          quantity: op.quantity,
          price: op.price,
          paidAmount: op.paidAmount,
          type: op.type,
          date: op.date,
        ),
      );
    }

    await transactionService.saveTransactions(transactions);

    customerNameController.clear();
    tempOperations.clear();

    await loadData();
  }

  int getSuppliersCount(Customer c) {
    return transactions
        .where((t) => t.customerId == c.id)
        .map((e) => e.supplierId)
        .toSet()
        .length;
  }

  double getTotal(Customer c) {
    return transactions
        .where((t) => t.customerId == c.id)
        .fold(0, (sum, t) => sum + (t.quantity * t.price));
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("الزبائن")),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),

        child: Column(
          children: [

            // 🔥 الجزء العلوي كامل (رجعناه)
            TextField(
              controller: customerNameController,
              decoration: InputDecoration(labelText: "اسم الزبون"),
            ),

            SizedBox(height: 10),

            DropdownButtonFormField<String>(
              hint: Text("اختر الرعوي"),
              value: selectedSupplierId,
              items: suppliers.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSupplierId = val;
                  selectedCategoryName = null;
                });
              },
            ),

            SizedBox(height: 10),

            DropdownButtonFormField<String>(
  hint: Text("اختر الفئة"),
  value: selectedCategoryName,
  items: selectedSupplierId == null
      ? []
      : getSelectedSupplier()
          .categories
          .map((c) {
            final supplier = getSelectedSupplier();
            double remaining = getRemaining(c, supplier);

            return DropdownMenuItem(
              value: c.name,
              enabled: remaining > 0,
              child: Text(
               "${c.name} - ${c.price} | متبقي: $remaining",
                style: TextStyle(
                  color: remaining > 0 ? Colors.white : Colors.grey,
                ),
              ),
            );
          })
          .toList(),

              onChanged: (val) {
                setState(() {
                  selectedCategoryName = val;
                });
              },
            ),

            SizedBox(height: 10),

            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "الكمية"),
            ),

            SizedBox(height: 10),

            TextField(
              controller: paidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "التسديد"),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: addTempOperation,
              child: Text("إضافة"),
            ),

            SizedBox(height: 20),

            Column(
              children: tempOperations.map((e) {
                return ListTile(
                  title: Text(e.categoryName),
                  subtitle: Text("${e.quantity}"),
                  trailing: Text("مدفوع: ${e.paidAmount}"),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveCustomer,
              child: Text("حفظ الزبون"),
            ),

            SizedBox(height: 20),

            // 🔥 الجدول مع الخيارات
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("الاسم")),
                  DataColumn(label: Text("عدد الرعيه")),
                  DataColumn(label: Text("الإجمالي")),
                  DataColumn(label: Text("➕")),
                  DataColumn(label: Text("خيارات")),
                ],
                rows: customers.map((c) {
                  return DataRow(cells: [

                    DataCell(
                      Text(c.name),
                  onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          CustomerDetailsScreen(customer: c),
    ),
  );

  await loadData();   // 🔥 الحل الحقيقي
  setState(() {});    // 🔥 تحديث فوري
},
                    ),

                    DataCell(Text("${getSuppliersCount(c)}")),
                    DataCell(Text("${getTotal(c)}")),

                    DataCell(
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          openAddOperationDialog(c);
                        },
                      ),
                    ),

                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editCustomer(c),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCustomer(c),
                          ),
                        ],
                      ),
                    ),

                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
