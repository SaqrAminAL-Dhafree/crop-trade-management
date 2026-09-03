import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mogot_app/core/pdf/day_details_pdf.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';

class DayFullDetailsScreen extends StatefulWidget {
  final String folderPath;

  DayFullDetailsScreen({required this.folderPath});

  @override
  _DayFullDetailsScreenState createState() =>
      _DayFullDetailsScreenState();
}

class _DayFullDetailsScreenState
    extends State<DayFullDetailsScreen> {

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> customers    = [];
  List<Map<String, dynamic>> suppliers    = [];

  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
     requestStoragePermission();
    loadData();
      

  }

Future<void> requestStoragePermission() async {

  if (await Permission.manageExternalStorage.isDenied) {

    await Permission.manageExternalStorage.request();
  }
}



  // =====================
  // 🖨️ تصدير PDF
  // =====================
  Future<void> _exportToPdf() async {
    try {
      final pdf = await generateDayDetailsPdf(
        folderPath: widget.folderPath,
        transactions: transactions,
        customers: customers,
        suppliers: suppliers,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ خطأ في تصدير PDF: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }








  Future<void> loadData() async {
    try {
      final t = await readFile("transactions.json");
      final c = await readFile("customers.json");
      final s = await readFile("suppliers.json");

      if (!mounted) return;

      setState(() {
        transactions = t;
        customers    = c;
        suppliers    = s;
        _isLoading   = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ خطأ في تحميل البيانات: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> readFile(String name) async {
    try {
      final file = File("${widget.folderPath}/$name");
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // =====================
  // 🔢 دوال مساعدة
  // =====================
  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> findCustomer(String customerId) {
    return customers.firstWhere(
      (c) => c["id"] == customerId,
      orElse: () => {"name": "غير معروف", "id": ""},
    );
  }

  Map<String, dynamic> findSupplier(String supplierId) {
    return suppliers.firstWhere(
      (s) => s["id"] == supplierId,
      orElse: () => {
        "name": "غير معروف",
        "id": "",
        "categories": <dynamic>[],
      },
    );
  }

  // =====================
  // 📊 بناء صفوف العمليات
  // =====================
  List<DataRow> _buildOperationRows() {

    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var t in transactions) {
      final supplierId   = t["supplierId"]?.toString()   ?? "";
      final categoryName = t["categoryName"]?.toString() ?? "";
      final key = "${supplierId}_${categoryName}";

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }

    return grouped.entries.map((entry) {

      final list = entry.value;

      double totalQty    = 0;
      double totalPaid   = 0;
      double totalAmount = 0;

      List<String> debtCustomers = [];

      for (var t in list) {
        final qty   = toDouble(t["quantity"]);
        final price = toDouble(t["price"]);
        final paid  = toDouble(t["paidAmount"]);

        totalQty    += qty;
        totalPaid   += paid;
        totalAmount += qty * price;

        final remaining = (qty * price) - paid;

        if (remaining > 0) {
          final customerId = t["customerId"]?.toString() ?? "";
          final customer   = findCustomer(customerId);
          final name       = customer["name"]?.toString() ?? "غير معروف";

          if (!debtCustomers.contains(name)) {
            debtCustomers.add(name);
          }
        }
      }

      final remainingAll = totalAmount - totalPaid;
      final categoryName = list.first["categoryName"]?.toString() ?? "";
      final unitPrice    = toDouble(list.first["price"]);
      final supplierId   = list.first["supplierId"]?.toString() ?? "";
      final supplier     = findSupplier(supplierId);
      final supplierName = supplier["name"]?.toString() ?? "غير معروف";

      double originalQty = 0;
      try {
        final categories = supplier["categories"];
        if (categories is List) {
          final matched = categories
              .whereType<Map>()
              .where((c) => c["name"] == categoryName)
              .toList();
          if (matched.isNotEmpty) {
            originalQty = toDouble(matched.first["quantity"]);
          }
        }
      } catch (_) {
        originalQty = 0;
      }

      final remainingQty = originalQty - totalQty;
      final isFinished   = totalQty >= originalQty && originalQty > 0;

      return DataRow(cells: [
        DataCell(Text(categoryName)),
        DataCell(Text(supplierName)),
        DataCell(Text(originalQty.toStringAsFixed(0))),
        DataCell(Text(totalQty.toStringAsFixed(0))),
        DataCell(Text(remainingQty.toStringAsFixed(0))),
        DataCell(Text(unitPrice.toStringAsFixed(0))),
        DataCell(Text(totalAmount.toStringAsFixed(0))),
        DataCell(Text(totalPaid.toStringAsFixed(0))),
        DataCell(Text(
          remainingAll.toStringAsFixed(0),
          style: TextStyle(
            color: remainingAll > 0 ? Colors.red : Colors.green,
          ),
        )),
        DataCell(Text(
          isFinished ? "❌ خلصت" : "✅ متوفرة",
          style: TextStyle(
            color: isFinished ? Colors.red : Colors.green,
          ),
        )),
        DataCell(Text(
          debtCustomers.isEmpty ? "-" : debtCustomers.join(", "),
        )),
      ]);

    }).toList();
  }

  int getTotalOperations() => transactions.length;
  int getCustomersCount()  => customers.length;
  int getSuppliersCount()  => suppliers.length;



  

  // =====================
  // 🏗️ البناء
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ الجديد
appBar: AppBar(
  title: Text("تفاصيل اليوم"),
  elevation: 0,
  actions: [
    // ✅ زر تصدير PDF
    IconButton(
      icon: Icon(Icons.picture_as_pdf),
      tooltip: "تصدير PDF",
      onPressed: _exportToPdf,
    ),
  ],
),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [

                  // ======================
                  // 🟢 ملخص
                  // ======================
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text("ملخص اليوم",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 10),
                          Text("عدد العمليات: ${getTotalOperations()}"),
                          Text("عدد الزبائن: ${getCustomersCount()}"),
                          Text("عدد المقوتين: ${getSuppliersCount()}"),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // ======================
                  // 🔵 العمليات
                  // ======================
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("تقرير العمليات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 10),
                          if (transactions.isEmpty)
                            Center(child: Text("لا توجد عمليات"))
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text("الفئة")),
                                  DataColumn(label: Text("المقوّت")),
                                  DataColumn(label: Text("الكمية الكلية")),
                                  DataColumn(label: Text("المباع")),
                                  DataColumn(label: Text("المتبقي")),
                                  DataColumn(label: Text("سعر الحبة")),
                                  DataColumn(label: Text("الإجمالي")),
                                  DataColumn(label: Text("المدفوع")),
                                  DataColumn(label: Text("المتبقي المالي")),
                                  DataColumn(label: Text("الحالة")),
                                  DataColumn(label: Text("الزبائن عليهم دين")),
                                ],
                                rows: _buildOperationRows(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // ======================
                  // 🟣 المقوتين - يظهر الكل
                  // ======================
                  Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("تقرير المقوتين",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),

                        if (suppliers.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text("لا يوجد مقوتين"),
                          )
                        else
                          // ✅ يظهر كل المقوتين سواء عندهم عمليات أو لا
                          ...suppliers.map((s) {

                            final supplierTx = transactions
                                .where((t) => t["supplierId"] == s["id"])
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // اسم المقوت
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.store,
                                          size: 16, color: Colors.purple),
                                      SizedBox(width: 6),
                                      Text(
                                        s["name"]?.toString() ?? "غير معروف",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),

                                // ✅ إذا لا توجد عمليات يظهر رسالة بدل إخفاء المقوت
                                if (supplierTx.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 14, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          "لا توجد عمليات لهذا المقوت",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: [
                                        DataColumn(label: Text("الفئة")),
                                        DataColumn(label: Text("الزبون")),
                                        DataColumn(label: Text("الكمية")),
                                        DataColumn(label: Text("المدفوع")),
                                        DataColumn(label: Text("المتبقي")),
                                      ],
                                      rows: supplierTx.map((t) {

                                        final customerId =
                                            t["customerId"]?.toString() ?? "";
                                        final customer =
                                            findCustomer(customerId);

                                        final qty   = toDouble(t["quantity"]);
                                        final price = toDouble(t["price"]);
                                        final paid  = toDouble(t["paidAmount"]);
                                        final total     = qty * price;
                                        final remaining = total - paid;

                                        return DataRow(cells: [
                                          DataCell(Text(
                                              t["categoryName"]?.toString() ?? "")),
                                          DataCell(Text(
                                              customer["name"]?.toString() ?? "غير معروف")),
                                          DataCell(Text(qty.toStringAsFixed(0))),
                                          DataCell(Text(paid.toStringAsFixed(0))),
                                          DataCell(Text(
                                            remaining.toStringAsFixed(0),
                                            style: TextStyle(
                                              color: remaining > 0
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          )),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),

                                Divider(),
                              ],
                            );
                          }).toList(),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  // ======================
                  // 🟠 الزبائن - يظهر الكل
                  // ======================
                  Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("تقرير الزبائن",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),

                        if (customers.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text("لا يوجد زبائن"),
                          )
                        else
                          // ✅ يظهر كل الزبائن سواء عندهم عمليات أو لا
                          ...customers.map((c) {

                            final customerTx = transactions
                                .where((t) => t["customerId"] == c["id"])
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // اسم الزبون
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person,
                                          size: 16, color: Colors.orange),
                                      SizedBox(width: 6),
                                      Text(
                                        c["name"]?.toString() ?? "غير معروف",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),

                                // ✅ إذا لا توجد عمليات يظهر رسالة بدل إخفاء الزبون
                                if (customerTx.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 14, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          "لا توجد عمليات لهذا الزبون",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: [
                                        DataColumn(label: Text("المقوت")),
                                        DataColumn(label: Text("الفئة")),
                                        DataColumn(label: Text("الكمية")),
                                        DataColumn(label: Text("الإجمالي")),
                                        DataColumn(label: Text("المدفوع")),
                                        DataColumn(label: Text("المتبقي")),
                                      ],
                                      rows: customerTx.map((t) {

                                        final supplierId =
                                            t["supplierId"]?.toString() ?? "";
                                        final supplier =
                                            findSupplier(supplierId);

                                        final qty   = toDouble(t["quantity"]);
                                        final price = toDouble(t["price"]);
                                        final paid  = toDouble(t["paidAmount"]);
                                        final total     = qty * price;
                                        final remaining = total - paid;

                                        return DataRow(cells: [
                                          DataCell(Text(
                                              supplier["name"]?.toString() ?? "غير معروف")),
                                          DataCell(Text(
                                              t["categoryName"]?.toString() ?? "")),
                                          DataCell(Text(qty.toStringAsFixed(0))),
                                          DataCell(Text(total.toStringAsFixed(0))),
                                          DataCell(Text(paid.toStringAsFixed(0))),
                                          DataCell(Text(
                                            remaining.toStringAsFixed(0),
                                            style: TextStyle(
                                              color: remaining > 0
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          )),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),

                                Divider(),
                              ],
                            );
                          }).toList(),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}