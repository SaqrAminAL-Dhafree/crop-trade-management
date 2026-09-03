import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../../features/transactions/models/transaction_model.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/suppliers/models/supplier_model.dart';

// 🔥 دوال عكس الأعمدة
List reverseRow(List row) => row.reversed.toList();
List<String> reverseHeaders(List<String> headers) =>
    headers.reversed.toList();

// =====================
// 🎨 الألوان الثابتة
// =====================

const PdfColor primaryColor =
    PdfColor.fromInt(0xFF1A237E);

const PdfColor accentColor =
    PdfColor.fromInt(0xFF1565C0);

const PdfColor supplierColor =
    PdfColor.fromInt(0xFF4A148C);

const PdfColor customerColor =
    PdfColor.fromInt(0xFF4A148C);

const PdfColor summaryBg =
    PdfColor.fromInt(0xFFF3F4F6);

const PdfColor rowEven =
    PdfColor.fromInt(0xFFEEF2FF);

const PdfColor dividerColor =
    PdfColor.fromInt(0xFFBBBBBB);

Future<pw.Document> generateReportPdf({
  required List<TransactionModel> transactions,
  required List<Customer> customers,
  required List<Supplier> suppliers,
}) async {

  final fontData = await rootBundle.load(
    "assets/fonts/Amiri-Regular.ttf",
  );

  final ttf = pw.Font.ttf(fontData);

  final pdf = pw.Document();

  final now = DateTime.now();

  String reportNumber =
      "${now.year}${now.month}${now.day}-${now.hour}${now.minute}";

  // =====================
  // 🔥 الحسابات العامة
  // =====================

  double totalSales = 0;
  double totalArsa = 0;
  double totalHaraj = 0;
  double totalTax = 0;
  double totalReceived = 0;
  double totalNet = 0;

  for (var t in transactions) {
    totalSales += t.quantity * t.price;
  }

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

  double totalExpenses =
      totalArsa +
      totalHaraj +
      totalTax +
      totalReceived;

  totalNet =
      totalSales - totalExpenses;

  // =====================
  // 🔤 أنماط النص
  // =====================

  pw.TextStyle styleSmall([
    PdfColor? color,
  ]) =>
      pw.TextStyle(
        font: ttf,
        fontSize: 9,
        color:
            color ?? PdfColors.black,
      );

  pw.TextStyle styleBold([
    PdfColor? color,
  ]) =>
      pw.TextStyle(
        font: ttf,
        fontSize: 10,
        fontWeight:
            pw.FontWeight.bold,
        color:
            color ?? PdfColors.black,
      );

  // =====================
  // 🧱 بطاقة ملخص
  // =====================

  pw.Widget summaryCard({
    required String label,
    required String value,
    required PdfColor color,
  }) {

    return pw.Expanded(

      child: pw.Container(

        margin:
            const pw.EdgeInsets.symmetric(
          horizontal: 4,
        ),

        padding:
            const pw.EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 6,
        ),

        decoration: pw.BoxDecoration(
          color: color,
          borderRadius:
              pw.BorderRadius.circular(6),
        ),

        child: pw.Column(

          crossAxisAlignment:
              pw.CrossAxisAlignment.center,

          children: [

            pw.Text(
              label,

              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color:
                    PdfColors.white,
              ),
            ),

            pw.SizedBox(height: 4),

            pw.Text(
              value,

              style: pw.TextStyle(
                font: ttf,
                fontSize: 12,
                fontWeight:
                    pw.FontWeight.bold,
                color:
                    PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // 🧱 عنوان قسم
  // =====================

  pw.Widget sectionTitle({
    required String text,
    required PdfColor color,
  }) {

    return pw.Container(

      width: double.infinity,

      padding:
          const pw.EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),

      decoration: pw.BoxDecoration(
        color: color,
        borderRadius:
            pw.BorderRadius.circular(6),
      ),

      child: pw.Text(

        text,

        style: pw.TextStyle(
          font: ttf,
          fontSize: 14,
          fontWeight:
              pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  // =====================
  // 🧱 عنوان عنصر
  // =====================

  pw.Widget itemTitle({
    required String text,
    required PdfColor color,
  }) {

    return pw.Container(

      width: double.infinity,

      padding:
          const pw.EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 10,
      ),

      decoration: pw.BoxDecoration(

        color: summaryBg,

        border: pw.Border(
          right: pw.BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),

      child: pw.Text(

        text,

        style: pw.TextStyle(
          font: ttf,
          fontSize: 12,
          fontWeight:
              pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  pdf.addPage(

    pw.MultiPage(

      pageFormat: PdfPageFormat.a4,

      textDirection:
          pw.TextDirection.rtl,

      margin:
          const pw.EdgeInsets.all(24),

      // =====================
      // 🔝 Header
      // =====================

      header: (context) {

        return pw.Column(

          children: [

            pw.Container(

              width: double.infinity,

              padding:
                  const pw.EdgeInsets.symmetric(
                vertical: 10,
              ),

              decoration:
                  const pw.BoxDecoration(
                color: primaryColor,
              ),

              child: pw.Column(

                children: [

                  pw.Text(

                    "حراج نشوان الصلاحي",

                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 24,
                      fontWeight:
                          pw.FontWeight.bold,
                      color:
                          PdfColors.white,
                    ),

                    textAlign:
                        pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 4),

                  pw.Text(

                    "تقرير يومي للمبيعات",

                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 13,
                      color:
                          PdfColors.white,
                    ),

                    textAlign:
                        pw.TextAlign.center,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text(
                  "رقم التقرير: $reportNumber",
                  style:
                      styleSmall(accentColor),
                ),

                pw.Text(
                  "التاريخ: ${now.year}-${now.month}-${now.day}",
                  style:
                      styleSmall(accentColor),
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            pw.Divider(
              color: dividerColor,
            ),
          ],
        );
      },

      // =====================
      // 🔚 Footer
      // =====================

      footer: (context) {

        return pw.Column(

          children: [

            pw.Divider(
              color: dividerColor,
            ),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text(
                  "حراج نشوان الصلاحي © جميع الحقوق محفوظة",
                  style: styleSmall(
                    PdfColors.grey600,
                  ),
                ),

                pw.Text(
                  "صفحة ${context.pageNumber} من ${context.pagesCount}",
                  style: styleSmall(
                    PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        );
      },

      build: (context) => [

        // =====================
        // 📊 الملخص العام
        // =====================

        pw.SizedBox(height: 8),

        sectionTitle(
          text: "📊 الملخص العام",
          color: primaryColor,
        ),

        pw.SizedBox(height: 10),

        pw.Row(

          children: [

            summaryCard(
              label: "إجمالي المبيعات",
              value:
                  totalSales
                      .toStringAsFixed(0),
              color: accentColor,
            ),

            summaryCard(
              label: "حراج نشوان الصلاحي",
              value: "✓",
              color: supplierColor,
            ),

            summaryCard(
              label: "الصافي العام",
              value:
                  totalNet
                      .toStringAsFixed(0),
              color: PdfColors.green,
            ),
          ],
        ),
      pw.SizedBox(height: 20),

pw.Container(

  padding: const pw.EdgeInsets.all(12),

  decoration: pw.BoxDecoration(

    color: summaryBg,

    borderRadius:
        pw.BorderRadius.circular(8),

    border: pw.Border.all(
      color: dividerColor,
      width: 0.5,
    ),
  ),

  child: pw.Column(

    children: [

      pw.Row(

        mainAxisAlignment:
            pw.MainAxisAlignment
                .spaceBetween,

        children: [

          pw.Text(
            "العرصة الكلية",
            style: styleBold(),
          ),

          pw.Text(
            totalArsa
                .toStringAsFixed(0),
            style: styleBold(
              PdfColors.red,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: 8),

      pw.Row(

        mainAxisAlignment:
            pw.MainAxisAlignment
                .spaceBetween,

        children: [

          pw.Text(
            "الحراج الكلي",
            style: styleBold(),
          ),

          pw.Text(
            totalHaraj
                .toStringAsFixed(0),
            style: styleBold(
              PdfColors.blue,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: 8),

      pw.Row(

        mainAxisAlignment:
            pw.MainAxisAlignment
                .spaceBetween,

        children: [

          pw.Text(
            "الضريبة الكلية",
            style: styleBold(),
          ),

          pw.Text(
            totalTax
                .toStringAsFixed(0),
            style: styleBold(
              PdfColors.orange,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: 8),

      pw.Row(

        mainAxisAlignment:
            pw.MainAxisAlignment
                .spaceBetween,

        children: [

          pw.Text(
            "الواصل الكلي",
            style: styleBold(),
          ),

          pw.Text(
            totalReceived
                .toStringAsFixed(0),
            style: styleBold(
              PdfColors.green,
            ),
          ),
        ],
      ),

      pw.Divider(),

      pw.Row(

        mainAxisAlignment:
            pw.MainAxisAlignment
                .spaceBetween,

        children: [

          pw.Text(
            "الصافي العام",
            style: styleBold(
              PdfColors.black,
            ),
          ),

          pw.Text(
            totalNet
                .toStringAsFixed(0),
            style: styleBold(
              PdfColors.green,
            ),
          ),
        ],
      ),
    ],
  ),
),


        pw.SizedBox(height: 24),

        // =====================
        // 📦 تقرير المقوتين
        // =====================

        sectionTitle(
          text: "📦 تقرير المقوتين",
          color: supplierColor,
        ),

        pw.SizedBox(height: 12),

        ...suppliers.map((s) {

          double supplierNet = 0;

          final tableData =
              s.categories.map((c) {

            double sold =
                transactions
                    .where(
                      (t) =>
                          t.supplierId ==
                              s.id &&
                          t.categoryName ==
                              c.name,
                    )
                    .fold(
                      0.0,
                      (sum, t) =>
                          sum +
                          t.quantity,
                    );

            double total =
                sold * c.price;

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

            supplierNet += net;

            final relatedTransactions =
                transactions.where(
              (t) =>
                  t.supplierId ==
                      s.id &&
                  t.categoryName ==
                      c.name,
            );

            String customersText =
                relatedTransactions
                    .map((t) {

              final customer =
                  customers.firstWhere(
                (cu) =>
                    cu.id ==
                    t.customerId,
              );

              return customer.name;

            }).join("\n");

            String quantitiesText =
                relatedTransactions
                    .map(
                      (t) => t.quantity
                          .toString(),
                    )
                    .join("\n");

            return reverseRow([

              c.name,

              c.quantity
                  .toString(),

              sold
                  .toStringAsFixed(0),

              c.price
                  .toStringAsFixed(0),

              total
                  .toStringAsFixed(0),

              customersText,

              quantitiesText,

              net
                  .toStringAsFixed(0),

              
            ]);

          }).toList();

          return pw.Column(

            crossAxisAlignment:
                pw.CrossAxisAlignment
                    .start,

            children: [

              itemTitle(
                text: s.name,
                color: supplierColor,
              ),

              pw.SizedBox(height: 6),

              pw.Table.fromTextArray(

                headerStyle: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                  color:
                      PdfColors.white,
                ),

                headerDecoration:
                    const pw.BoxDecoration(
                  color: supplierColor,
                ),

                cellStyle: styleSmall(),

                cellAlignment:
                    pw.Alignment.center,

                border:
                    pw.TableBorder.all(
                  color: dividerColor,
                  width: 0.5,
                ),

                headers: reverseHeaders([

                  "الفئة",

                  "الأصل",

                  "المباع",

                  "السعر",

                  "الإجمالي",

                  "الزبائن",

                  "الكميات",

                  "الصافي",

                  
                ]),

                data: tableData,
              ),

              pw.SizedBox(height: 16),
            ],
          );

        }).toList(),

        pw.SizedBox(height: 20),

        // =====================
        // 👤 تقرير الزبائن
        // =====================

        sectionTitle(
          text: "👤 تقرير الزبائن",
          color: customerColor,
        ),

        pw.SizedBox(height: 12),

        ...customers.map((c) {

          final customerTx =
              transactions.where(
            (t) =>
                t.customerId == c.id,
          ).toList();

          if (customerTx.isEmpty) {
            return pw.SizedBox();
          }

          final tableData =
              customerTx.map((t) {

            final supplier =
                suppliers.firstWhere(
              (s) =>
                  s.id ==
                  t.supplierId,
            );

            double total =
                t.quantity * t.price;

            return reverseRow([

              supplier.name,

              t.categoryName,

              t.quantity.toString(),

              total
                  .toStringAsFixed(0),

              total
                  .toStringAsFixed(0),
            ]);

          }).toList();

          return pw.Column(

            crossAxisAlignment:
                pw.CrossAxisAlignment
                    .start,

            children: [

              itemTitle(
                text: c.name,
                color: customerColor,
              ),

              pw.SizedBox(height: 6),

              pw.Table.fromTextArray(

                headerStyle: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                  color:
                      PdfColors.white,
                ),

                headerDecoration:
                    const pw.BoxDecoration(
                  color: customerColor,
                ),

                cellStyle: styleSmall(),

                cellAlignment:
                    pw.Alignment.center,

                border:
                    pw.TableBorder.all(
                  color: dividerColor,
                  width: 0.5,
                ),

                headers: reverseHeaders([

                  "المقوت",

                  "الفئة",

                  "الكمية",

                  "الإجمالي",

                  "الدين",
                ]),

                data: tableData,
              ),

              pw.SizedBox(height: 16),
            ],
          );

        }).toList(),
      ],
    ),
  );

  return pdf;
}