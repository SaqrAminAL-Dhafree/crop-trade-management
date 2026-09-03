import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

// =====================
// 🎨 الألوان
// =====================
const PdfColor primaryColor    = PdfColor.fromInt(0xFF1A237E);
const PdfColor accentColor     = PdfColor.fromInt(0xFF1565C0);
const PdfColor supplierColor   = PdfColor.fromInt(0xFF4A148C);
const PdfColor customerColor   = PdfColor.fromInt(0xFF4A148C);
const PdfColor operationColor  = PdfColor.fromInt(0xFF0277BD);
const PdfColor summaryBg       = PdfColor.fromInt(0xFFF3F4F6);
const PdfColor debtColor       = PdfColor.fromInt(0xFFB71C1C);
const PdfColor paidColor       = PdfColor.fromInt(0xFF1B5E20);
const PdfColor dividerColor    = PdfColor.fromInt(0xFFBBBBBB);

Future<pw.Document> generateDayDetailsPdf({
  required String folderPath,
  required List<Map<String, dynamic>> transactions,
  required List<Map<String, dynamic>> customers,
  required List<Map<String, dynamic>> suppliers,
}) async {

  final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  // =====================
  // 🔤 أنماط النصوص
  // =====================
  pw.TextStyle styleSmall([PdfColor? color]) =>
      pw.TextStyle(font: ttf, fontSize: 8, color: color ?? PdfColors.black);

  pw.TextStyle styleBold([PdfColor? color]) => pw.TextStyle(
        font: ttf,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: color ?? PdfColors.black,
      );

  // =====================
  // 🧱 عنوان عنصر
  // =====================
  pw.Widget itemTitle({
    required String text,
    required PdfColor color,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: summaryBg,
        border: pw.Border(
          right: pw.BorderSide(color: color, width: 4),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: ttf,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // =====================
  // 🧱 ملخص بطاقة
  // =====================
  pw.Widget summaryBox({
    required String name,
    required double total,
    required double paid,
    required double debt,
    required PdfColor color,
    required PdfColor bgColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "ملخص",
            style: styleBold(color),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("الإجمالي: ", style: styleSmall(PdfColors.grey700)),
              pw.Text(total.toStringAsFixed(0), style: styleBold(accentColor)),
              pw.SizedBox(width: 8),
              pw.Text("المدفوع: ", style: styleSmall(PdfColors.grey700)),
              pw.Text(paid.toStringAsFixed(0), style: styleBold(paidColor)),
              pw.SizedBox(width: 8),
              pw.Text("المتبقي: ", style: styleSmall(PdfColors.grey700)),
              pw.Text(debt.toStringAsFixed(0), style: styleBold(debtColor)),
            ],
          ),
        ],
      ),
    );
  }

  // =====================
  // 🔢 دوال مساعدة
  // =====================
  double toDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Map<String, dynamic> findCustomer(String? customerId) {
    if (customerId == null || customerId.isEmpty) {
      return {"name": "غير معروف", "id": ""};
    }
    return customers.firstWhere(
      (c) => c["id"]?.toString() == customerId,
      orElse: () => {"name": "غير معروف", "id": customerId},
    );
  }

  Map<String, dynamic> findSupplier(String? supplierId) {
    if (supplierId == null || supplierId.isEmpty) {
      return {"name": "غير معروف", "id": "", "categories": <dynamic>[]};
    }
    return suppliers.firstWhere(
      (s) => s["id"]?.toString() == supplierId,
      orElse: () => {
        "name": "غير معروف",
        "id": supplierId,
        "categories": <dynamic>[],
      },
    );
  }

  // =====================
  // 🔄 دالة عكس الجداول
  // =====================
  List<List<String>> reverseTableRows(List<List<String>> rows) {
    return rows.map((row) => row.reversed.toList()).toList();
  }

  List<String> reverseHeaders(List<String> headers) {
    return headers.reversed.toList();
  }

  // =====================
  // 📊 حسابات
  // =====================
  int getTotalOperations() => transactions.length;
  int getCustomersCount() => customers.length;
  int getSuppliersCount() => suppliers.length;

  double getTotalSales() {
    return transactions.fold(0.0, (sum, t) {
      return sum + (toDouble(t["quantity"]) * toDouble(t["price"]));
    });
  }

  double getTotalPaid() {
    return transactions.fold(
        0.0, (sum, t) => sum + toDouble(t["paidAmount"]));
  }

  // =====================
  // 📋 بناء صفوف العمليات
  // =====================
  List<List<String>> buildOperationRows() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var t in transactions) {
      final supplierId = t["supplierId"]?.toString() ?? "";
      final categoryName = t["categoryName"]?.toString() ?? "";

      if (supplierId.isEmpty || categoryName.isEmpty) continue;

      final key = "${supplierId}_${categoryName}";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }

    final rows = <List<String>>[];

    for (var entry in grouped.entries) {
      final list = entry.value;
      if (list.isEmpty) continue;

      double totalQty = 0;
      double totalPaid = 0;
      double totalAmount = 0;
      Set<String> debtCustomers = {};

      for (var t in list) {
        final qty = toDouble(t["quantity"]);
        final price = toDouble(t["price"]);
        final paid = toDouble(t["paidAmount"]);

        totalQty += qty;
        totalPaid += paid;
        totalAmount += qty * price;

        final remaining = (qty * price) - paid;
        if (remaining > 0) {
          final customer = findCustomer(t["customerId"]?.toString());
          debtCustomers.add(customer["name"]?.toString() ?? "غير معروف");
        }
      }

      final categoryName = list.first["categoryName"]?.toString() ?? "";
      final unitPrice = toDouble(list.first["price"]);
      final supplierId = list.first["supplierId"]?.toString() ?? "";
      final supplier = findSupplier(supplierId);
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
      } catch (_) {}

      final remainingQty = originalQty - totalQty;
      final remainingAll = totalAmount - totalPaid;
      final isFinished = originalQty > 0 && totalQty >= originalQty;

      rows.add([
        categoryName,
        supplierName,
        originalQty.toStringAsFixed(0),
        totalQty.toStringAsFixed(0),
        remainingQty.toStringAsFixed(0),
        unitPrice.toStringAsFixed(0),
        totalAmount.toStringAsFixed(0),
        totalPaid.toStringAsFixed(0),
        remainingAll.toStringAsFixed(0),
        isFinished ? "❌ خلصت" : "✅ متوفرة",
        debtCustomers.isEmpty ? "-" : debtCustomers.join(", "),
      ]);
    }

    return rows;
  }

  final pdf = pw.Document();
  final now = DateTime.now();
  final reportNumber =
      "${now.year}${now.month}${now.day}-${now.hour}${now.minute}";

  final totalSales = getTotalSales();
  final totalPaid = getTotalPaid();
  final totalDebt = totalSales - totalPaid;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(20),

      // =====================
      // 🔝 الترويسة
      // =====================
      header: (context) => pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: const pw.BoxDecoration(color: primaryColor),
            child: pw.Column(
              children: [
                pw.Text(
                  "حراج نشوان الصلاحي",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "تقرير تفاصيل اليوم",
                  style: pw.TextStyle(
                      font: ttf, fontSize: 13, color: PdfColors.white),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: summaryBg,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  "رقم التقرير: $reportNumber",
                  style: styleSmall(accentColor),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: summaryBg,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  "التاريخ: ${now.year}-${now.month}-${now.day}",
                  style: styleSmall(accentColor),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: dividerColor, thickness: 1),
        ],
      ),

      // =====================
      // 🔚 التذييل
      // =====================
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: dividerColor, thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("حراج نشوان الصلاحي  © جميع الحقوق محفوظة ",
                  style: styleSmall(PdfColors.grey600)),
              pw.Text(
                "صفحة ${context.pageNumber} من ${context.pagesCount}",
                style: styleSmall(PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),

      build: (context) => [

        pw.SizedBox(height: 8),

        // =====================
        // 🟢 ملخص اليوم
        // =====================
       pw.Container(
  padding: const pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    // ✅ بدون لون خلفي
    border: pw.Border.all(color: primaryColor, width: 1),
    borderRadius: pw.BorderRadius.circular(6),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        "📊 ملخص اليوم",
        style: pw.TextStyle(
          font: ttf,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("عدد العمليات: ${getTotalOperations()}",
              style: styleSmall()),
          pw.Text("عدد الزبائن: ${getCustomersCount()}",
              style: styleSmall()),
          pw.Text("عدد المقوتين: ${getSuppliersCount()}",
              style: styleSmall()),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("المبيعات: ${totalSales.toStringAsFixed(0)}",
              style: styleBold(accentColor)),
          pw.Text("المدفوع: ${totalPaid.toStringAsFixed(0)}",
              style: styleBold(paidColor)),
          pw.Text("الديون: ${totalDebt.toStringAsFixed(0)}",
              style: styleBold(debtColor)),
        ],
      ),
    ],
  ),
),
        pw.SizedBox(height: 16),

        // =====================
        // 🔵 تقرير العمليات
        // =====================
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: operationColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            "📋 تقرير العمليات",
            style: pw.TextStyle(
              font: ttf,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 8),

        if (transactions.isEmpty)
          pw.Center(
            child: pw.Text("لا توجد عمليات",
                style: styleSmall(PdfColors.grey600)),
          )
        else
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              font: ttf,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: operationColor),
            cellDecoration: (index, data, rowNum) => pw.BoxDecoration(
              color: rowNum.isOdd
                  ? PdfColors.white
                  : const PdfColor.fromInt(0xFFEEF2FF),
            ),
            cellStyle: pw.TextStyle(
              font: ttf,
              fontSize: 7,
            ),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(
              color: dividerColor,
              width: 0.5,
            ),
            cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 2, horizontal: 2),
            // ✅ عكس الأعمدة
            headers: reverseHeaders([
              "الفئة",
              "المقوّت",
              "الكمية\nالكلية",
              "المباع",
              "المتبقي",
              "سعر\nالحبة",
              "الإجمالي",
              "المدفوع",
              "المتبقي\nالمالي",
              "الحالة",
              "الزبائن\nعليهم دين",
            ]),
            // ✅ عكس البيانات
            data: reverseTableRows(buildOperationRows()),
          ),

        pw.SizedBox(height: 20),

        // =====================
        // 🟣 تقرير المقوتين
        // =====================
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: supplierColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            "🏪 تقرير المقوتين",
            style: pw.TextStyle(
              font: ttf,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 8),

        if (suppliers.isEmpty)
          pw.Text("لا يوجد مقوتين", style: styleSmall(PdfColors.grey600))
        else
          pw.Column(
            children: suppliers.map((s) {

              final supplierId = s["id"]?.toString() ?? "";
              final supplierTx = transactions
                  .where((t) => t["supplierId"]?.toString() == supplierId)
                  .toList();

              final supplierTotal = supplierTx.fold<double>(
                  0.0,
                  (sum, t) =>
                      sum +
                      (toDouble(t["quantity"]) * toDouble(t["price"])));

              final supplierPaid = supplierTx.fold<double>(
                  0.0, (sum, t) => sum + toDouble(t["paidAmount"]));

              final supplierDebt = supplierTotal - supplierPaid;

              final tableData = supplierTx.map((t) {
                final customer = findCustomer(t["customerId"]?.toString());
                final qty = toDouble(t["quantity"]);
                final price = toDouble(t["price"]);
                final paid = toDouble(t["paidAmount"]);
                final total = qty * price;
                final remaining = total - paid;

                return [
                  t["categoryName"]?.toString() ?? "",
                  customer["name"]?.toString() ?? "غير معروف",
                  qty.toStringAsFixed(0),
                  paid.toStringAsFixed(0),
                  remaining.toStringAsFixed(0),
                ];
              }).toList();

              return pw.Column(
                children: [
                  // ✅ عنوان بدون لون خلفي
                  itemTitle(
                    text: s["name"]?.toString() ?? "غير معروف",
                    color: supplierColor,
                  ),

                  pw.SizedBox(height: 6),

                  // الجدول
                  if (supplierTx.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: pw.Text(
                        "لا توجد عمليات لهذا المقوت",
                        style: styleSmall(PdfColors.grey600),
                      ),
                    )
                  else
                    pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(
                        font: ttf,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration:
                          const pw.BoxDecoration(color: supplierColor),
                      cellDecoration: (index, data, rowNum) =>
                          pw.BoxDecoration(
                        color: rowNum.isOdd
                            ? PdfColors.white
                            : const PdfColor.fromInt(0xFFEEF2FF),
                      ),
                      cellStyle: pw.TextStyle(
                        font: ttf,
                        fontSize: 7,
                      ),
                      cellAlignment: pw.Alignment.center,
                      border: pw.TableBorder.all(
                        color: dividerColor,
                        width: 0.5,
                      ),
                      cellPadding: const pw.EdgeInsets.symmetric(
                          vertical: 2, horizontal: 2),
                      // ✅ عكس الأعمدة
                      headers: reverseHeaders(
                          ["الفئة", "الزبون", "الكمية", "المدفوع", "المتبقي"]),
                      // ✅ عكس البيانات
                      data: reverseTableRows(tableData),
                    ),

                  pw.SizedBox(height: 6),

                  // ✅ ملخص المقوت
                  summaryBox(
                    name: s["name"]?.toString() ?? "غير معروف",
                    total: supplierTotal,
                    paid: supplierPaid,
                    debt: supplierDebt,
                    color: supplierColor,
                    bgColor: const PdfColor.fromInt(0xFFF3E5F5),
                  ),

                  pw.SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),

        pw.SizedBox(height: 16),

        // =====================
        // 🟠 تقرير الزبائن
        // =====================
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: customerColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            "👥 تقرير الزبائن",
            style: pw.TextStyle(
              font: ttf,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 8),

        if (customers.isEmpty)
          pw.Text("لا يوجد زبائن", style: styleSmall(PdfColors.grey600))
        else
          pw.Column(
            children: customers.map((c) {

              final customerId = c["id"]?.toString() ?? "";
              final customerTx = transactions
                  .where((t) => t["customerId"]?.toString() == customerId)
                  .toList();

              final customerTotal = customerTx.fold<double>(
                  0.0,
                  (sum, t) =>
                      sum +
                      (toDouble(t["quantity"]) * toDouble(t["price"])));

              final customerPaid = customerTx.fold<double>(
                  0.0, (sum, t) => sum + toDouble(t["paidAmount"]));

              final customerDebt = customerTotal - customerPaid;

              final tableData = customerTx.map((t) {
                final supplier = findSupplier(t["supplierId"]?.toString());
                final qty = toDouble(t["quantity"]);
                final price = toDouble(t["price"]);
                final paid = toDouble(t["paidAmount"]);
                final total = qty * price;
                final remaining = total - paid;

                return [
                  supplier["name"]?.toString() ?? "غير معروف",
                  t["categoryName"]?.toString() ?? "",
                  qty.toStringAsFixed(0),
                  total.toStringAsFixed(0),
                  paid.toStringAsFixed(0),
                  remaining.toStringAsFixed(0),
                ];
              }).toList();

              return pw.Column(
                children: [
                  // ✅ عنوان بدون لون خلفي
                  itemTitle(
                    text: c["name"]?.toString() ?? "غير معروف",
                    color: customerColor,
                  ),

                  pw.SizedBox(height: 6),

                  // الجدول
                  if (customerTx.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: pw.Text(
                        "لا توجد عمليات لهذا الزبون",
                        style: styleSmall(PdfColors.grey600),
                      ),
                    )
                  else
                    pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(
                        font: ttf,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration:
                          const pw.BoxDecoration(color: customerColor),
                      cellDecoration: (index, data, rowNum) =>
                          pw.BoxDecoration(
                        color: rowNum.isOdd
                            ? PdfColors.white
                            : const PdfColor.fromInt(0xFFFFF3E0),
                      ),
                      cellStyle: pw.TextStyle(
                        font: ttf,
                        fontSize: 7,
                      ),
                      cellAlignment: pw.Alignment.center,
                      border: pw.TableBorder.all(
                        color: dividerColor,
                        width: 0.5,
                      ),
                      cellPadding: const pw.EdgeInsets.symmetric(
                          vertical: 2, horizontal: 2),
                      // ✅ عكس الأعمدة
                      headers: reverseHeaders([
                        "المقوت",
                        "الفئة",
                        "الكمية",
                        "الإجمالي",
                        "المدفوع",
                        "المتبقي"
                      ]),
                      // ✅ عكس البيانات
                      data: reverseTableRows(tableData),
                    ),

                  pw.SizedBox(height: 6),

                  // ✅ ملخص الزبون
                  summaryBox(
                    name: c["name"]?.toString() ?? "غير معروف",
                    total: customerTotal,
                    paid: customerPaid,
                    debt: customerDebt,
                    color: customerColor,
                    bgColor: const PdfColor.fromInt(0xFFFFF3E0),
                  ),

                  pw.SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),
      ],
    ),
  );

  return pdf;
}