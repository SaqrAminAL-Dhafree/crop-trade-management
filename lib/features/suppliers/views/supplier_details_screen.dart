import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../controllers/supplier_service.dart';

// 🔥 جديد
import '../../transactions/services/transaction_service.dart';
import '../../customers/controllers/customer_service.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final Supplier supplier;
  final int index;

  const SupplierDetailsScreen({
    required this.supplier,
    required this.index,
  });

  @override
  _SupplierDetailsScreenState createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState
    extends State<SupplierDetailsScreen> {

  final SupplierService service = SupplierService();

  // 🔥 جديد
  final TransactionService transactionService = TransactionService();
  final CustomerService customerService = CustomerService();

  List transactions = [];
  List customers = [];

  late List<Category> categories;

  @override
  void initState() {
    super.initState();

    categories = widget.supplier.categories
        .map((c) => Category(
              name: c.name,
              price: c.price,
              quantity: c.quantity,
            ))
        .toList();

    loadExtraData(); // 🔥 جديد
  }

  // 🔥 جديد
  Future<void> loadExtraData() async {
    transactions = await transactionService.getTransactions();
    customers = await customerService.getCustomers();
    setState(() {});
  }

  // 🔥 جديد
  String getCustomerName(String id) {
    try {
      return customers.firstWhere((c) => c.id == id).name;
    } catch (e) {
      return "غير معروف";
    }
  }

  // 🔥 جديد (تجميع الزبائن)
  List<Widget> _buildCustomersForCategory(String categoryName) {

    var related = transactions.where((t) =>
        t.supplierId == widget.supplier.id &&
        t.categoryName == categoryName);

    Map<String, double> grouped = {};

    for (var t in related) {
      grouped[t.customerId] =
          (grouped[t.customerId] ?? 0) + t.quantity;
    }

    return grouped.entries.map((entry) {
      return Text(
        "👤 ${getCustomerName(entry.key)} أخذ: ${entry.value}",
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      );
    }).toList();
  }

  void editCategory(int index) {
    final c = categories[index];

    TextEditingController priceEdit =
        TextEditingController(text: c.price.toString());

    TextEditingController qtyEdit =
        TextEditingController(text: c.quantity.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("تعديل الفئة"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceEdit,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "السعر",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: qtyEdit,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "الكمية",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
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
            onPressed: () {
              double? newPrice = double.tryParse(priceEdit.text);
              double? newQty = double.tryParse(qtyEdit.text);

              if (newPrice != null && newQty != null) {
                setState(() {
                  categories[index] = Category(
                    name: c.name,
                    price: newPrice,
                    quantity: newQty,
                  );
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("يرجى إدخال أرقام صحيحة")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text("تحديث الشاشة", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("تأكيد"),
        content: Text("هل تريد الحذف؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                categories.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("نعم"),
          ),
        ],
      ),
    );
  }

  Future<void> saveChanges() async {
    try {
      var suppliers = await service.getSuppliers();

      int index = suppliers.indexWhere(
          (s) => s.id == widget.supplier.id);

      if (index == -1) return;

      suppliers[index] = Supplier(
        id: widget.supplier.id,
        name: widget.supplier.name,
        categories: categories.map((c) => Category(
          name: c.name,
          price: c.price,
          quantity: c.quantity,
        )).toList(),
        receivedAmount: widget.supplier.receivedAmount,
      );

      await service.saveSuppliers(suppliers);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ تم حفظ التعديلات في الملف بنجاح!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء الحفظ: $e")),
      );
    }
  }

  void confirmSave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("تأكيد الحفظ"),
        content: Text("هل تريد حفظ كافة التعديلات في الملف بشكل دائم؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              saveChanges();
            },
            child: Text("حفظ الآن"),
          ),
        ],
      ),
    );
  }
  void showCategoryCustomers(String categoryName) {

  var related = transactions.where((t) =>
      t.supplierId == widget.supplier.id &&
      t.categoryName == categoryName);

  Map<String, double> grouped = {};

  for (var t in related) {
    grouped[t.customerId] =
        (grouped[t.customerId] ?? 0) + t.quantity;
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("تفاصيل الفئة: $categoryName"),

      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // 🔥 مهم للتمرير
        child: grouped.isEmpty
            ? Center(child: Text("لا يوجد عمليات"))
            : ListView(
                children: grouped.entries.map((entry) {

                  String name = getCustomerName(entry.key);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),

                    child: Padding(
                      padding: EdgeInsets.all(10),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 🔥 الاسم كامل بدون قص
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            softWrap: true,
                          ),

                          SizedBox(height: 5),

                          // 🔥 سطر ثاني للكمية
                          Text(
                            "الكمية: ${entry.value}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  );

                }).toList(),
              ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("إغلاق"),
        )
      ],
    ),
  );
}

double calculateTotalSales() {
  double total = 0;

  for (var t in transactions) {
    if (t.supplierId == widget.supplier.id) {
      total += t.quantity * t.price;
    }
  }

  return total;
}

double calculateArsa(double total) {
  return total < 100000 ? 500 : 1000;
}

double calculateHaraj(double total) {
  return total * 0.05;
}

double calculateTax(double total) {
  return total * 0.03;
}

double calculateNet(double total) {
  return total - (calculateArsa(total) + calculateHaraj(total) + calculateTax(total)+ (widget.supplier.receivedAmount));
}
Widget buildRow(String title, double value, {bool isImportant = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontWeight: isImportant ? FontWeight.bold : null,
            color: isImportant ? Colors.green : null,
          ),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {

    double totalQty = 0;
    double totalValue = 0;
    double totalSales = calculateTotalSales();
double arsa = calculateArsa(totalSales);
double haraj = calculateHaraj(totalSales);
double tax = calculateTax(totalSales);
double net = calculateNet(totalSales);
double received = widget.supplier.receivedAmount;

    for (var c in categories) {
      totalQty += c.quantity;
      totalValue += (c.price * c.quantity);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.supplier.name)),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [

              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text("إجمالي الكمية", style: TextStyle(color: Colors.grey)),
                          Text("$totalQty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text("إجمالي القيمة", style: TextStyle(color: Colors.grey)),
                          Text("$totalValue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 10),
             
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text("تفاصيل المبيعات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("إجمالي المبيعات"),
                          Text("$totalSales"),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("العرصة"),
                          Text("$arsa"),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("الحراج"),
                          Text("$haraj"),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("الضريبة"),
                          Text("$tax"),
                        ],
                      ),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("الواصل "),
                          Text("$received"),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("الصافي  ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("$net", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),


              SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];

                  return Card(
                    child: ListTile(
                      title: InkWell(
  onTap: () => showCategoryCustomers(c.name),
  child: Text(
    c.name,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline, // 🔥 يعطي إحساس قابل للضغط
    ),
  ),
),

                      // 🔥 التعديل هنا فقط
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("سعر: ${c.price} | كمية: ${c.quantity}"),
                          Text("الإجمالي: ${c.price * c.quantity}"),
                          SizedBox(height: 5),
                          
                        ],
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editCategory(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: confirmSave,
                  icon: Icon(Icons.save),
                  label: Text("حفظ التعديلات نهائياً", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
            ],
          ),
        ),
      ),
    );
  }
}