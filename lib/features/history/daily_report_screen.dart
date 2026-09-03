import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

// Models
import 'package:mogot_app/features/customers/models/customer_model.dart';
import 'package:mogot_app/features/suppliers/models/supplier_model.dart';
import 'package:mogot_app/features/transactions/models/transaction_model.dart';

// Services
import 'package:mogot_app/features/customers/controllers/customer_service.dart';
import 'package:mogot_app/features/suppliers/controllers/supplier_service.dart';
import 'package:mogot_app/features/transactions/services/transaction_service.dart';

// PDF
import 'package:mogot_app/core/pdf/report_pdf.dart';

class DailyReportScreen extends StatefulWidget {
  @override
  State<DailyReportScreen> createState() =>
      _DailyReportScreenState();
}

class _DailyReportScreenState
    extends State<DailyReportScreen> {

  final customerService = CustomerService();
  final supplierService = SupplierService();
  final transactionService = TransactionService();

  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<TransactionModel> transactions = [];

  double totalSales = 0;
  double totalDebt = 0;

  // 🔥 الحسابات الكلية
  double totalHaraj = 0;
  double totalTax = 0;
  double totalArsa = 0;
  double totalReceived = 0;
  double totalNet = 0;

  Widget _summaryItem(
    String title,
    double value, {
    bool isRed = false,
  }) {

    return Column(
      children: [

        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 5),

        Text(
          value.toStringAsFixed(0),

          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:
                isRed ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    customers =
        await customerService.getCustomers();

    suppliers =
        await supplierService.getSuppliers();

    transactions =
        await transactionService.getTransactions();

    totalSales = 0;
    totalDebt = 0;

    totalHaraj = 0;
    totalTax = 0;
    totalArsa = 0;
    totalReceived = 0;
    totalNet = 0;

    // 🔥 إجمالي المبيعات
    for (var t in transactions) {
      totalSales += t.quantity * t.price;
    }

    // 🔥 كل المبيعات تعتبر ديون
    totalDebt = totalSales;

    // 🔥 الحسابات الكلية
    for (var s in suppliers) {

      double supplierTotal = 0;

      for (var t in transactions) {
        if (t.supplierId == s.id) {
          supplierTotal +=
              t.quantity * t.price;
        }
      }

      double arsa =
          supplierTotal < 100000
              ? 500
              : 1000;

      double haraj =
          supplierTotal * 0.05;

      double tax =
          supplierTotal * 0.03;

      totalArsa += arsa;
      totalHaraj += haraj;
      totalTax += tax;

      totalReceived += s.receivedAmount;
    }

    // 🔥 الصافي العام
  // 🔥 مجموع الخصومات الكلية
double totalExpenses =
    totalArsa +
    totalHaraj +
    totalTax +
    totalReceived;

// 🔥 الصافي العام
totalNet =
    totalSales - totalExpenses;

    setState(() {});
  }

  double getSold(
    String supplierId,
    String categoryName,
  ) {

    return transactions
        .where(
          (t) =>
              t.supplierId == supplierId &&
              t.categoryName ==
                  categoryName,
        )
        .fold(
          0.0,
          (sum, t) => sum + t.quantity,
        );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("📊 تقرير اليوم"),

        actions: [

          IconButton(
            icon: Icon(Icons.print),

            onPressed: () async {

              final pdf =
                  await generateReportPdf(
                transactions: transactions,
                customers: customers,
                suppliers: suppliers,
              );

              await Printing.layoutPdf(
                onLayout: (format) =>
                    pdf.save(),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.all(12),

        child: Column(
          children: [

            // 🟢 البطاقات الأساسية
            Card(

              elevation: 3,

              child: Padding(

                padding: EdgeInsets.all(15),

                child: Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [

                    _summaryItem(
                      "المبيعات",
                      totalSales,
                    ),

                    Container(
                      height: 40,
                      width: 1,
                      color:
                          Colors.grey.shade300,
                    ),

                  Icon(
      Icons.store,
      color: Colors.blue,
      size: 28,
    ),

                    Container(
                      height: 40,
                      width: 1,
                      color:
                          Colors.grey.shade300,
                    ),

                    _summaryItem(
                      "الصافي",
                      totalNet,
                      isRed:
                          totalNet < 0,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 15),

            // 🔥 البطاقة المالية
            Card(
              child: Padding(
                padding:
                    EdgeInsets.all(12),

                child: Column(
                  children: [

                    _row(
                      "العرصة الكلية",
                      totalArsa,
                    ),

                    _row(
                      "الحراج الكلي",
                      totalHaraj,
                    ),

                    _row(
                      "الضريبة الكلية",
                      totalTax,
                    ),

                    _row(
                      "الواصل الكلي",
                      totalReceived,
                    ),

                    Divider(),

                    _row(
                      "الصافي العام",
                      totalNet,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 🟣 تقرير المقوتين
            _title("📦 تقرير الرعيه"),

            ...suppliers.map((s) {

              return Card(

                child: Column(
                  children: [

                    Padding(

                      padding:
                          EdgeInsets.all(10),

                      child: Column(
                        children: [

                          Text(
                            s.name,

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "الواصل: ${s.receivedAmount.toStringAsFixed(0)}",

                            style: TextStyle(
                              color:
                                  Colors.green,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SingleChildScrollView(

                      scrollDirection:
                          Axis.horizontal,

                      child: DataTable(

                        dataRowMinHeight:
                            60,

                        dataRowMaxHeight:
                            150,

                        columns: [

                          DataColumn(
                              label:
                                  Text("الفئة")),

                          DataColumn(
                              label:
                                  Text("الأصل")),

                          DataColumn(
                              label:
                                  Text("المباع")),

                          DataColumn(
                              label:
                                  Text("المتبقي")),

                          DataColumn(
                              label:
                                  Text("السعر")),

                          DataColumn(
                              label:
                                  Text("الإجمالي")),

                          DataColumn(
                              label:
                                  Text("الزبائن")),

                          DataColumn(
                              label:
                                  Text("الكميات")),

                          DataColumn(
                              label:
                                  Text("الصافي")),
                        ],

                        rows:
                            s.categories.map((c) {

                          double sold =
                              getSold(
                            s.id,
                            c.name,
                          );

                          double remain =
                              c.quantity -
                                  sold;

                          double price =
                              c.price;

                          double total =
                              sold * price;

                          double arsa =
                              total < 100000
                                  ? 500
                                  : 1000;

                          double haraj =
                              total * 0.05;

                          double tax =
                              total * 0.03;

                          double net =
                              total
                              - arsa
                              - haraj
                              - tax;

                          final relatedTransactions =
                              transactions.where(
                            (t) =>
                                t.supplierId ==
                                    s.id &&
                                t.categoryName ==
                                    c.name,
                          );

                          return DataRow(
                            cells: [

                              DataCell(
                                  Text(c.name)),

                              DataCell(
                                Text(
                                    "${c.quantity}"),
                              ),

                              DataCell(
                                Text("$sold"),
                              ),

                              DataCell(
                                Text("$remain"),
                              ),

                              DataCell(
                                Text(
                                  price
                                      .toStringAsFixed(
                                          0),
                                ),
                              ),

                              DataCell(
                                Text(
                                  total
                                      .toStringAsFixed(
                                          0),
                                ),
                              ),

                              // 🔥 الزبائن
                              DataCell(

                                SingleChildScrollView(

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children:
                                        relatedTransactions
                                            .map((t) {

                                      final customer =
                                          customers.firstWhere(
                                        (cu) =>
                                            cu.id ==
                                            t.customerId,
                                      );

                                      return Padding(
                                        padding:
                                            EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),

                                        child: Text(
                                          customer.name,
                                        ),
                                      );

                                    }).toList(),
                                  ),
                                ),
                              ),

                              // 🔥 الكميات
                              DataCell(

                                SingleChildScrollView(

                                  child: Column(

                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children:
                                        relatedTransactions
                                            .map((t) {

                                      return Padding(

                                        padding:
                                            EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),

                                        child: Text(
                                          "${t.quantity}",
                                        ),
                                      );

                                    }).toList(),
                                  ),
                                ),
                              ),

                              // 🔥 الصافي
                              DataCell(

                                Text(

                                  net
                                      .toStringAsFixed(
                                          0),

                                  style: TextStyle(
                                    color:
                                        net > 0
                                            ? Colors
                                                .green
                                            : Colors
                                                .red,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ],
                          );

                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );

            }).toList(),

            SizedBox(height: 20),

            // 🟠 تقرير الزبائن
            _title("👤 تقرير الزبائن"),

            ...customers.map((c) {

              final tx =
                  transactions.where(
                (t) =>
                    t.customerId == c.id,
              ).toList();

              if (tx.isEmpty)
                return SizedBox();

              return Card(

                child: Column(
                  children: [

                    Padding(

                      padding:
                          EdgeInsets.all(10),

                      child: Text(

                        c.name,

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    SingleChildScrollView(

                      scrollDirection:
                          Axis.horizontal,

                      child: DataTable(

                        columns: [

                          DataColumn(
                              label:
                                  Text("الرعوي")),

                          DataColumn(
                              label:
                                  Text("الفئة")),

                          DataColumn(
                              label:
                                  Text("الكمية")),

                          DataColumn(
                              label:
                                  Text("الإجمالي")),

                          DataColumn(
                              label:
                                  Text("الدين")),
                        ],

                        rows: tx.map((t) {

                          final supplier =
                              suppliers.firstWhere(
                            (s) =>
                                s.id ==
                                t.supplierId,
                          );

                          double total =
                              t.quantity *
                                  t.price;

                          return DataRow(
                            cells: [

                              DataCell(
                                Text(
                                    supplier.name),
                              ),

                              DataCell(
                                Text(
                                    t.categoryName),
                              ),

                              DataCell(
                                Text(
                                    "${t.quantity}"),
                              ),

                              DataCell(
                                Text(
                                  total
                                      .toStringAsFixed(
                                          0),
                                ),
                              ),

                              DataCell(

                                Text(

                                  total
                                      .toStringAsFixed(
                                          0),

                                  style: TextStyle(
                                    color:
                                        Colors.red,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ],
                          );

                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );

            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _card(
    String title,
    double value, {
    bool isRed = false,
  }) {

    return Expanded(
      child: Card(

        child: Padding(

          padding: EdgeInsets.all(10),

          child: Column(
            children: [

              Text(title),

              SizedBox(height: 5),

              Text(

                value.toStringAsFixed(0),

                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,

                  color:
                      isRed
                          ? Colors.red
                          : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 صف البطاقة المالية
  Widget _row(
    String title,
    double value,
  ) {

    return Padding(

      padding:
          EdgeInsets.symmetric(
        vertical: 5,
      ),

      child: Row(

        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [

          Text(title),

          Text(

            value.toStringAsFixed(0),

            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) {

    return Align(

      alignment:
          Alignment.centerRight,

      child: Padding(

        padding:
            EdgeInsets.symmetric(
          vertical: 8,
        ),

        child: Text(

          text,

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}