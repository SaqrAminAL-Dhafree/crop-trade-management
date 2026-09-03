import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../controllers/supplier_service.dart';
import 'supplier_details_screen.dart';

class SupplierScreen extends StatefulWidget {
  @override
  _SupplierScreenState createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {

  final SupplierService service = SupplierService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController receivedController = TextEditingController();

  List<Category> categories = [];
  List<Supplier> suppliers = [];

  double totalValue = 0;
  double totalQty = 0;

  @override
  void initState() {
    super.initState();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    suppliers = await service.getSuppliers();
    setState(() {});
  }

  void calculateTotals() {
    totalValue = 0;
    totalQty = 0;

    for (var c in categories) {
      totalValue += (c.price * c.quantity); // حساب الإجمالي الفعلي
      totalQty += c.quantity;
    }
  }

  void addCategory() {
    double price = double.tryParse(priceController.text) ?? 0;
    double qty = double.tryParse(qtyController.text) ?? 0;

    if (price == 0 || qty == 0) return;

    setState(() {
      categories.add(Category(
        name: "فئة ${categories.length + 1}",
        price: price,
        quantity: qty,
      ));

      priceController.clear();
      qtyController.clear();

      calculateTotals();
    });
  }

  // 🔥 حفظ مقوت
  Future<void> saveSupplier() async {
  FocusScope.of(context).unfocus();

  if (nameController.text.isEmpty || categories.isEmpty) return;

  // 🔥 قراءة الواصل
  double received = double.tryParse(receivedController.text) ?? 0;

  Supplier newSupplier = Supplier(
    id: DateTime.now().toString(),
    name: nameController.text,
    categories: categories,

    // 🔥 الجديد
    receivedAmount: received,
  );

  suppliers.add(newSupplier);

  await service.saveSuppliers(suppliers);
  await loadSuppliers();

  // 🔥 تنظيف الحقول
  nameController.clear();
  receivedController.clear(); // 🔥 مهم
  categories.clear();
  totalQty = 0;
  totalValue = 0;
  receivedController.clear();

  setState(() {});
}

  // ✏️ تعديل المقوت
void editSupplier(int index) {
  final s = suppliers[index];

  TextEditingController nameEdit =
      TextEditingController(text: s.name);

  TextEditingController receivedEdit =
      TextEditingController(text: s.receivedAmount.toString());

  showDialog(
    context: context,
    builder: (_) {
      return Dialog( // 🔥 بدل AlertDialog
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // 🔥 أكبر عرض
          padding: EdgeInsets.all(20),

          child: SingleChildScrollView( // 🔥 يمنع الخط الأصفر
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  "تعديل المقوّت",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 15),

                // الاسم
                TextField(
                  controller: nameEdit,
                  decoration: InputDecoration(
                    labelText: "الاسم",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 15),

                // الواصل
                TextField(
                  controller: receivedEdit,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "الواصل",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("إلغاء"),
                    ),

                    SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () async {

                        double newReceived =
                            double.tryParse(receivedEdit.text) ?? 0;

                        suppliers[index] = Supplier(
                          id: s.id,
                          name: nameEdit.text,
                          categories: s.categories,
                          receivedAmount: newReceived,
                        );

                        await service.saveSuppliers(suppliers);
                        await loadSuppliers();

                        Navigator.pop(context);
                      },
                      child: Text("حفظ"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  // ❌ حذف المقوت
 Future<void> deleteSupplier(int index) async {

  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("تأكيد الحذف"),
     content: Text("سيتم حذف المقوّت وكل بياناته، هل أنت متأكد؟"),
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

  suppliers.removeAt(index);
  await service.saveSuppliers(suppliers);
  await loadSuppliers();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("الرعيه")),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),

          child: Column(
            children: [

              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "اسم الرعوي"),
              ),
            
              SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "السعر"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "العدد"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: addCategory,
                  )
                ],
              ),

              SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text("عدد العلاقيات: $totalQty"),
                      Text("الإجمالي: $totalValue"),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),
TextField(
  controller: receivedController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(labelText: "الواصل"),
),
SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saveSupplier,
                  child: Text("حفظ"),
                ),
              ),

              SizedBox(height: 20),

              // 🔵 جدول
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("الاسم")),
                    DataColumn(label: Text("الفئات")),
                    DataColumn(label: Text("الكمية")),
                    DataColumn(label: Text("الإجمالي")),
                    DataColumn(label: Text("الواصل")),
                    DataColumn(label: Text("خيارات")),
                  ],
                  rows: suppliers.asMap().entries.map((entry) {
                    int index = entry.key;
                    var s = entry.value;

                    double total = 0;
                    double qty = 0;

                    for (var c in s.categories) {
                      total += (c.price * c.quantity);
                      qty += c.quantity;
                    }

                    return DataRow(cells: [
                      DataCell(
                        Text(s.name),
                        onTap: () async { // 🔥 هنا التعديل المهم
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SupplierDetailsScreen(
                                    supplier: s,
                                    index: index,
                                  ),
                            ),
                          );
                          // إذا تم إرجاع true من شاشة التفاصيل، قم بتحديث البيانات
                          if (result == true) {
                            loadSuppliers();
                          }
                        },
                      ),
                      DataCell(Text("${s.categories.length}")),
                      DataCell(Text("$qty")),
                      DataCell(Text("$total")),
DataCell(Text("${s.receivedAmount}")),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            color: Colors.blue,
                            onPressed: () => editSupplier(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => deleteSupplier(index),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
